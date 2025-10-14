# Azure Network 모듈
# 공용 IP, 서브넷, NSG 등 네트워크 리소스 통합 관리

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# 기존 리소스 그룹 참조
data "azurerm_resource_group" "existing" {
  name = var.resource_group_name
}

# 기존 Virtual Network 참조
data "azurerm_virtual_network" "existing" {
  name                = var.existing_vnet_name
  resource_group_name = var.resource_group_name
}

# 기존 서브넷 참조
data "azurerm_subnet" "existing" {
  count                = var.use_existing_subnet ? 1 : 0
  name                 = var.existing_subnet_name
  virtual_network_name = data.azurerm_virtual_network.existing.name
  resource_group_name  = var.resource_group_name
}

# 기존 NSG 참조 (필수)
data "azurerm_network_security_group" "existing" {
  name                = var.existing_nsg_name
  resource_group_name = var.resource_group_name
}

# ========================================
# 공용 IP 생성 (서브모듈 사용)
# ========================================
module "public_ip" {
  source = "./public-ip"
  
  resource_group_name = var.resource_group_name
  create_public_ip   = var.create_public_ip
  create_linux_pip   = var.create_linux_pip
  create_windows_pip = var.create_windows_pip
  public_ip_name_prefix = var.public_ip_name_prefix
  allocation_method  = var.public_ip_allocation_method
  sku               = var.public_ip_sku
  availability_zones = var.public_ip_zones
  domain_name_label = var.public_ip_domain_name_label
  idle_timeout_in_minutes = var.public_ip_idle_timeout_in_minutes
  create_public_ip_prefix = var.create_public_ip_prefix
  public_ip_prefix_length = var.public_ip_prefix_length
  tags = var.tags
}

# ========================================
# 서브넷 생성 (새로 생성하는 경우)
# ========================================
resource "azurerm_subnet" "main" {
  count                = var.create_new_subnet ? var.subnet_count : 0
  name                 = var.subnet_count > 1 ? "${var.subnet_name_prefix}-${count.index + 1}" : var.subnet_name_prefix
  resource_group_name  = data.azurerm_resource_group.existing.name
  virtual_network_name = data.azurerm_virtual_network.existing.name
  address_prefixes     = [var.subnet_address_prefixes[count.index]]

  # 서브넷에 연결할 서비스 위임 (필요시)
  dynamic "delegation" {
    for_each = var.subnet_service_delegations
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_name
        actions = delegation.value.actions
      }
    }
  }
}

# ========================================
# 서브넷과 NSG 연결 (기존 NSG 사용)
# ========================================
resource "azurerm_subnet_network_security_group_association" "main" {
  count                     = var.associate_subnet_nsg ? 1 : 0
  subnet_id                 = var.use_existing_subnet ? data.azurerm_subnet.existing[0].id : azurerm_subnet.main[0].id
  network_security_group_id = data.azurerm_network_security_group.existing.id
}
