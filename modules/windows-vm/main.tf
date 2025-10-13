# Windows VM 모듈 - 전용 모듈

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
  
}


# Windows VM용 Public IP
# Windows VM용 Public IP는 네트워크 모듈에서 관리

# Windows VM용 Network Interface
resource "azurerm_network_interface" "windows_vm" {
  count               = var.windows_vm_count
  name                = "${length(var.windows_vm_names) > count.index ? var.windows_vm_names[count.index] : "${var.vm_name_prefix}-windows-${count.index + 1}"}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = local.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.windows_public_ip_id
  }

  tags = var.tags
}

# Network Security Group을 Network Interface에 연결
resource "azurerm_network_interface_security_group_association" "windows_vm" {
  count                     = var.windows_vm_count
  network_interface_id      = azurerm_network_interface.windows_vm[count.index].id
  network_security_group_id = local.nsg_id
}

# Windows Server VM
resource "azurerm_windows_virtual_machine" "main" {
  count               = var.windows_vm_count
  name                = length(var.windows_vm_names) > count.index ? var.windows_vm_names[count.index] : "${var.vm_name_prefix}-windows-${count.index + 1}"
  computer_name       = length(var.windows_vm_names) > count.index ? substr(var.windows_vm_names[count.index], 0, 15) : "vm-win-${count.index + 1}"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.windows_vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  availability_set_id = var.availability_set_id
  zone               = var.availability_zone


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
    storage_account_type = var.windows_storage_account_type
    disk_size_gb         = var.os_disk_size_gb
  }

  # 마켓플레이스 이미지 사용
  source_image_reference {
    publisher = var.windows_vm_image_publisher
    offer     = var.windows_vm_image_offer
    sku       = var.windows_vm_image_sku
    version   = var.windows_vm_image_version
  }

  # 부팅 진단
  dynamic "boot_diagnostics" {
    for_each = var.enable_boot_diagnostics ? [1] : []
    content {
      storage_account_uri = var.boot_diagnostics_storage_account_uri
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      vm_agent_platform_updates_enabled
    ]
  }
}

# Windows VM 데이터 디스크 - 사용하지 않음

# Windows VM 확장 설치
resource "azurerm_virtual_machine_extension" "windows_extensions" {
  for_each = var.install_vm_extensions ? var.windows_vm_extensions : {}

  name                 = each.key
  virtual_machine_id   = azurerm_windows_virtual_machine.main[0].id
  publisher            = each.value.publisher
  type                 = each.value.type
  type_handler_version = each.value.type_handler_version

  settings          = jsonencode(each.value.settings)
  protected_settings = jsonencode(each.value.protected_settings)

  tags = var.tags
}

# Windows VM Custom Script Extension
resource "azurerm_virtual_machine_extension" "windows_custom_script" {
  count                = var.windows_vm_count > 0 && var.install_vm_extensions ? 1 : 0
  name                 = "custom-script-windows"
  virtual_machine_id   = azurerm_windows_virtual_machine.main[0].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    fileUris = ["https://stterraformstatecjs2.blob.core.windows.net/terraform-state/scripts/install-windows-en.ps1"]
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -File C:\\Packages\\Plugins\\Microsoft.Compute.CustomScriptExtension\\1.10.20\\Downloads\\0\\scripts\\install-windows-en.ps1"
  })

  tags = var.tags

  depends_on = [azurerm_windows_virtual_machine.main]
}

# Windows VM 관리 ID 역할 할당
resource "azurerm_role_assignment" "windows_vm" {
  for_each = var.windows_vm_count > 0 && var.enable_managed_identity && length(var.role_assignments) > 0 ? var.role_assignments : {}

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = azurerm_windows_virtual_machine.main[0].identity[0].principal_id

  depends_on = [azurerm_windows_virtual_machine.main]
}

# Windows VM 설정 안내를 위한 Local 값
locals {
  windows_setup_instructions = var.windows_vm_count > 0 && var.install_azure_cli ? [
    "Windows VM 설정 방법:",
    "1. RDP 접속: mstsc /v:${azurerm_windows_virtual_machine.main[0].public_ip_address}",
    "2. Custom Script Extension을 통해 install-windows-en.ps1이 자동 실행됩니다",
    "3. 설치 로그는 C:\\vm-setup.log에서 확인 가능합니다"
  ] : []
}
