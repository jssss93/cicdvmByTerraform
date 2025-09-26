# Linux VM 모듈 - 전용 모듈

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
  
  # Linux bash 스크립트 (Azure CLI 및 도구 설치)  
  linux_script = var.install_azure_cli ? base64encode(templatefile("${path.module}/scripts/install-linux.sh", {
    custom_script = var.custom_script_linux
  })) : null
  
  # Cloud-init 스크립트 생성
  cloud_init_script = var.install_azure_cli ? templatefile("${path.module}/scripts/cloud-init.yaml", {
    custom_script = var.custom_script_linux
  }) : null
}


# Linux VM용 Public IP는 네트워크 모듈에서 관리

# Linux VM용 Network Interface
resource "azurerm_network_interface" "linux_vm" {
  count               = var.linux_vm_count
  name                = "${length(var.linux_vm_names) > count.index ? var.linux_vm_names[count.index] : "${var.vm_name_prefix}-linux-${count.index + 1}"}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = local.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.linux_public_ip_id
  }

  tags = var.tags
}

# Network Security Group을 Network Interface에 연결
resource "azurerm_network_interface_security_group_association" "linux_vm" {
  count                     = var.linux_vm_count
  network_interface_id      = azurerm_network_interface.linux_vm[count.index].id
  network_security_group_id = local.nsg_id
}

# Linux VM
resource "azurerm_linux_virtual_machine" "main" {
  count               = var.linux_vm_count
  name                = length(var.linux_vm_names) > count.index ? var.linux_vm_names[count.index] : "${var.vm_name_prefix}-linux-${count.index + 1}"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.linux_vm_size
  admin_username      = var.admin_username

  disable_password_authentication = false
  admin_password                  = var.admin_password

  availability_set_id = var.availability_set_id
  zone               = var.availability_zone
  
  # Cloud-init 스크립트 주입
  custom_data = var.install_azure_cli ? base64encode(local.cloud_init_script) : null

  # SSH 키 설정 (선택적)
  dynamic "admin_ssh_key" {
    for_each = var.ssh_public_key != null ? [1] : []
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
    storage_account_type = var.linux_storage_account_type
    disk_size_gb         = var.os_disk_size_gb
  }

  # 마켓플레이스 이미지 사용
  source_image_reference {
    publisher = var.linux_vm_image_publisher
    offer     = var.linux_vm_image_offer
    sku       = var.linux_vm_image_sku
    version   = var.linux_vm_image_version
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

# Linux VM 데이터 디스크 - 사용하지 않음

# Linux VM 확장 설치
resource "azurerm_virtual_machine_extension" "linux_extensions" {
  for_each = var.install_vm_extensions ? var.linux_vm_extensions : {}

  name                 = each.key
  virtual_machine_id   = azurerm_linux_virtual_machine.main[0].id
  publisher            = each.value.publisher
  type                 = each.value.type
  type_handler_version = each.value.type_handler_version

  settings          = jsonencode(each.value.settings)
  protected_settings = jsonencode(each.value.protected_settings)

  tags = var.tags
}

# Linux VM Custom Script Extension (Base64 인코딩 방식) 
resource "azurerm_virtual_machine_extension" "linux_custom_script" {
  count                = var.linux_vm_count > 0 && var.custom_script_linux != "" ? 1 : 0
  name                 = "custom-script-linux"
  virtual_machine_id   = azurerm_linux_virtual_machine.main[0].id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = jsonencode({
    script = base64encode(var.custom_script_linux)
  })

  tags = var.tags

  depends_on = [azurerm_linux_virtual_machine.main]
}

# Linux VM 관리 ID 역할 할당
resource "azurerm_role_assignment" "linux_vm" {
  for_each = var.linux_vm_count > 0 && var.enable_managed_identity && length(var.role_assignments) > 0 ? var.role_assignments : {}

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = azurerm_linux_virtual_machine.main[0].identity[0].principal_id

  depends_on = [azurerm_linux_virtual_machine.main]
}
