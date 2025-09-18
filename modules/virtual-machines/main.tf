# 가상머신 모듈 - 완전 변수화

# 기존 네트워킹 리소스 데이터 소스
data "azurerm_virtual_network" "existing" {
  count               = var.existing_vnet_name != null ? 1 : 0
  name                = var.existing_vnet_name
  resource_group_name = var.resource_group_name
}

data "azurerm_subnet" "existing" {
  count                = var.existing_subnet_name != null ? 1 : 0
  name                 = var.existing_subnet_name
  virtual_network_name = var.existing_vnet_name
  resource_group_name  = var.resource_group_name
}

data "azurerm_network_security_group" "existing" {
  count               = var.existing_nsg_name != null ? 1 : 0
  name                = var.existing_nsg_name
  resource_group_name = var.resource_group_name
}

# 실제 사용할 리소스 ID 결정
locals {
  subnet_id = var.subnet_id != null ? var.subnet_id : (
    var.existing_subnet_name != null ? data.azurerm_subnet.existing[0].id : null
  )
  nsg_id = var.nsg_id != null ? var.nsg_id : (
    var.existing_nsg_name != null ? data.azurerm_network_security_group.existing[0].id : null
  )
  
  # Windows PowerShell 스크립트 (Azure CLI 및 .NET SDK 설치)
  windows_script = var.install_azure_cli ? base64encode(templatefile("${path.module}/scripts/install-windows.ps1", {
    custom_script = var.custom_script_windows
  })) : null
  
  # Linux bash 스크립트 (Azure CLI 및 도구 설치)  
  linux_script = var.install_azure_cli ? base64encode(templatefile("${path.module}/scripts/install-linux.sh", {
    custom_script = var.custom_script_linux
  })) : null
}

# 랜덤 패스워드 생성 (admin_password가 제공되지 않은 경우)
resource "random_password" "vm_password" {
  count   = var.admin_password == null ? 1 : 0
  length  = 16
  special = true
}

# Windows VM용 Public IP
resource "azurerm_public_ip" "windows_vm" {
  count               = var.create_windows_vm && var.create_public_ip ? var.windows_vm_count : 0
  name                = "${length(var.windows_vm_names) > count.index ? var.windows_vm_names[count.index] : "${var.vm_name_prefix}-windows-${count.index + 1}"}-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = var.public_ip_allocation_method
  sku                 = var.public_ip_sku

  tags = var.tags
}

# Linux VM용 Public IP
resource "azurerm_public_ip" "linux_vm" {
  count               = var.create_linux_vm && var.create_public_ip ? var.linux_vm_count : 0
  name                = "${length(var.linux_vm_names) > count.index ? var.linux_vm_names[count.index] : "${var.vm_name_prefix}-linux-${count.index + 1}"}-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = var.public_ip_allocation_method
  sku                 = var.public_ip_sku

  tags = var.tags
}

# Windows VM용 Network Interface
resource "azurerm_network_interface" "windows_vm" {
  count               = var.create_windows_vm ? var.windows_vm_count : 0
  name                = "${length(var.windows_vm_names) > count.index ? var.windows_vm_names[count.index] : "${var.vm_name_prefix}-windows-${count.index + 1}"}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = local.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.create_public_ip ? azurerm_public_ip.windows_vm[count.index].id : null
  }

  tags = var.tags
}

# Linux VM용 Network Interface
resource "azurerm_network_interface" "linux_vm" {
  count               = var.create_linux_vm ? var.linux_vm_count : 0
  name                = "${length(var.linux_vm_names) > count.index ? var.linux_vm_names[count.index] : "${var.vm_name_prefix}-linux-${count.index + 1}"}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = local.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.create_public_ip ? azurerm_public_ip.linux_vm[count.index].id : null
  }

  tags = var.tags
}

# Network Security Group을 Network Interface에 연결
resource "azurerm_network_interface_security_group_association" "windows_vm" {
  count                     = var.create_windows_vm ? var.windows_vm_count : 0
  network_interface_id      = azurerm_network_interface.windows_vm[count.index].id
  network_security_group_id = local.nsg_id
}

resource "azurerm_network_interface_security_group_association" "linux_vm" {
  count                     = var.create_linux_vm ? var.linux_vm_count : 0
  network_interface_id      = azurerm_network_interface.linux_vm[count.index].id
  network_security_group_id = local.nsg_id
}

# Windows Server VM
resource "azurerm_windows_virtual_machine" "main" {
  count               = var.create_windows_vm ? var.windows_vm_count : 0
  name                = length(var.windows_vm_names) > count.index ? var.windows_vm_names[count.index] : "${var.vm_name_prefix}-windows-${count.index + 1}"
  computer_name       = length(var.windows_vm_names) > count.index ? substr(var.windows_vm_names[count.index], 0, 15) : "vm-win-${count.index + 1}"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.windows_vm_size != "Standard_B2s" ? var.windows_vm_size : var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password != null ? var.admin_password : random_password.vm_password[0].result

  availability_set_id = var.availability_set_id
  zone               = var.availability_zone
  
  # Azure CLI 설치 스크립트 주입
  custom_data = local.windows_script

  network_interface_ids = [
    azurerm_network_interface.windows_vm[count.index].id,
  ]
  
  # 관리 ID 설정
  dynamic "identity" {
    for_each = var.enable_managed_identity ? [1] : []
    content {
      type         = var.managed_identity_type
      identity_ids = var.managed_identity_type == "UserAssigned" || var.managed_identity_type == "SystemAssigned,UserAssigned" ? var.user_assigned_identity_ids : null
    }
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.windows_storage_account_type != "Premium_LRS" ? var.windows_storage_account_type : var.storage_account_type
    disk_size_gb         = var.os_disk_size_gb
  }

  # 마켓플레이스 이미지 사용
  source_image_reference {
    publisher = var.windows_image_publisher
    offer     = var.windows_image_offer
    sku       = var.windows_image_sku
    version   = var.windows_image_version
  }

  # 부팅 진단
  dynamic "boot_diagnostics" {
    for_each = var.enable_boot_diagnostics ? [1] : []
    content {
      storage_account_uri = var.boot_diagnostics_storage_account_uri
    }
  }

  tags = var.tags
}

# Linux VM
resource "azurerm_linux_virtual_machine" "main" {
  count               = var.create_linux_vm ? var.linux_vm_count : 0
  name                = length(var.linux_vm_names) > count.index ? var.linux_vm_names[count.index] : "${var.vm_name_prefix}-linux-${count.index + 1}"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.linux_vm_size != "Standard_B2s" ? var.linux_vm_size : var.vm_size
  admin_username      = var.admin_username

  disable_password_authentication = var.disable_password_authentication
  admin_password                  = var.disable_password_authentication ? null : (var.admin_password != null ? var.admin_password : random_password.vm_password[0].result)

  availability_set_id = var.availability_set_id
  zone               = var.availability_zone
  
  # Azure CLI 설치 스크립트 주입
  custom_data = local.linux_script

  # SSH 키 설정 (비밀번호 인증이 비활성화된 경우)
  dynamic "admin_ssh_key" {
    for_each = var.disable_password_authentication && var.ssh_public_key != null ? [1] : []
    content {
      username   = var.admin_username
      public_key = var.ssh_public_key
    }
  }

  network_interface_ids = [
    azurerm_network_interface.linux_vm[count.index].id,
  ]
  
  # 관리 ID 설정
  dynamic "identity" {
    for_each = var.enable_managed_identity ? [1] : []
    content {
      type         = var.managed_identity_type
      identity_ids = var.managed_identity_type == "UserAssigned" || var.managed_identity_type == "SystemAssigned,UserAssigned" ? var.user_assigned_identity_ids : null
    }
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.linux_storage_account_type != "Premium_LRS" ? var.linux_storage_account_type : var.storage_account_type
    disk_size_gb         = var.os_disk_size_gb
  }

  # 마켓플레이스 이미지 사용
  source_image_reference {
    publisher = var.linux_image_publisher
    offer     = var.linux_image_offer
    sku       = var.linux_image_sku
    version   = var.linux_image_version
  }

  # 부팅 진단
  dynamic "boot_diagnostics" {
    for_each = var.enable_boot_diagnostics ? [1] : []
    content {
      storage_account_uri = var.boot_diagnostics_storage_account_uri
    }
  }

  tags = var.tags
}

# Windows VM 데이터 디스크 생성
resource "azurerm_managed_disk" "windows_data_disk" {
  count                = var.create_windows_vm && var.create_data_disk ? var.windows_vm_count : 0
  name                 = "${length(var.windows_vm_names) > count.index ? var.windows_vm_names[count.index] : "${var.vm_name_prefix}-windows-${count.index + 1}"}-data-disk"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = var.data_disk_storage_account_type
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size_gb

  tags = var.tags
}

# Windows VM 데이터 디스크 연결
resource "azurerm_virtual_machine_data_disk_attachment" "windows_data_disk" {
  count              = var.create_windows_vm && var.create_data_disk ? var.windows_vm_count : 0
  managed_disk_id    = azurerm_managed_disk.windows_data_disk[count.index].id
  virtual_machine_id = azurerm_windows_virtual_machine.main[count.index].id
  lun                = var.data_disk_lun
  caching            = var.data_disk_caching
}

# Linux VM 데이터 디스크 생성
resource "azurerm_managed_disk" "linux_data_disk" {
  count                = var.create_linux_vm && var.create_data_disk ? var.linux_vm_count : 0
  name                 = "${length(var.linux_vm_names) > count.index ? var.linux_vm_names[count.index] : "${var.vm_name_prefix}-linux-${count.index + 1}"}-data-disk"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = var.data_disk_storage_account_type
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size_gb

  tags = var.tags
}

# Linux VM 데이터 디스크 연결
resource "azurerm_virtual_machine_data_disk_attachment" "linux_data_disk" {
  count              = var.create_linux_vm && var.create_data_disk ? var.linux_vm_count : 0
  managed_disk_id    = azurerm_managed_disk.linux_data_disk[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.main[count.index].id
  lun                = var.data_disk_lun
  caching            = var.data_disk_caching
}

# Windows VM 확장 설치
resource "azurerm_virtual_machine_extension" "windows_extensions" {
  for_each = var.install_vm_extensions && var.create_windows_vm ? var.windows_vm_extensions : {}

  name                 = each.key
  virtual_machine_id   = azurerm_windows_virtual_machine.main[0].id
  publisher            = each.value.publisher
  type                 = each.value.type
  type_handler_version = each.value.type_handler_version

  settings          = jsonencode(each.value.settings)
  protected_settings = jsonencode(each.value.protected_settings)

  tags = var.tags
}

# Linux VM 확장 설치
resource "azurerm_virtual_machine_extension" "linux_extensions" {
  for_each = var.install_vm_extensions && var.create_linux_vm ? var.linux_vm_extensions : {}

  name                 = each.key
  virtual_machine_id   = azurerm_linux_virtual_machine.main[0].id
  publisher            = each.value.publisher
  type                 = each.value.type
  type_handler_version = each.value.type_handler_version

  settings          = jsonencode(each.value.settings)
  protected_settings = jsonencode(each.value.protected_settings)

  tags = var.tags
}

# Windows VM 관리 ID 역할 할당
resource "azurerm_role_assignment" "windows_vm" {
  for_each = var.create_windows_vm && var.enable_managed_identity && length(var.role_assignments) > 0 ? var.role_assignments : {}

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = azurerm_windows_virtual_machine.main[0].identity[0].principal_id

  depends_on = [azurerm_windows_virtual_machine.main]
}

# Linux VM 관리 ID 역할 할당
resource "azurerm_role_assignment" "linux_vm" {
  for_each = var.create_linux_vm && var.enable_managed_identity && length(var.role_assignments) > 0 ? var.role_assignments : {}

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = azurerm_linux_virtual_machine.main[0].identity[0].principal_id

  depends_on = [azurerm_linux_virtual_machine.main]
}