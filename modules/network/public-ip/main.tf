# Azure Public IP 모듈
# 환경별 공용 IP 생성 및 관리

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

# Linux VM용 공용 IP 생성
resource "azurerm_public_ip" "linux" {
  count               = var.create_public_ip && var.create_linux_pip ? 1 : 0
  name                = "${var.public_ip_name_prefix}-linux"
  location            = data.azurerm_resource_group.existing.location
  resource_group_name = data.azurerm_resource_group.existing.name
  
  allocation_method = var.allocation_method
  sku               = var.sku
  zones             = var.availability_zones
  
  # 도메인 이름 라벨 (선택적)
  domain_name_label = var.domain_name_label != null ? "${var.domain_name_label}-linux" : null
  
  # Idle timeout 설정
  idle_timeout_in_minutes = var.idle_timeout_in_minutes
  
  tags = var.tags
}

# Windows VM용 공용 IP 생성
resource "azurerm_public_ip" "windows" {
  count               = var.create_public_ip && var.create_windows_pip ? 1 : 0
  name                = "${var.public_ip_name_prefix}-windows"
  location            = data.azurerm_resource_group.existing.location
  resource_group_name = data.azurerm_resource_group.existing.name
  
  allocation_method = var.allocation_method
  sku               = var.sku
  zones             = var.availability_zones
  
  # 도메인 이름 라벨 (선택적)
  domain_name_label = var.domain_name_label != null ? "${var.domain_name_label}-windows" : null
  
  # Idle timeout 설정
  idle_timeout_in_minutes = var.idle_timeout_in_minutes
  
  tags = var.tags
}

# Public IP Prefix (선택적)
resource "azurerm_public_ip_prefix" "main" {
  count               = var.create_public_ip_prefix ? 1 : 0
  name                = "${var.public_ip_name_prefix}-prefix"
  location            = data.azurerm_resource_group.existing.location
  resource_group_name = data.azurerm_resource_group.existing.name
  
  prefix_length = var.public_ip_prefix_length
  zones         = var.availability_zones
  
  tags = var.tags
}
