# Azure Provider 설정
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
  # backend "azurerm" {
  #   resource_group_name  = "rg-az01-poc-hyundai.teams-01"
  #   storage_account_name = "stterraformstatecjs2"
  #   container_name       = "terraform-state"
  #   key                  = "terraform.tfstate"
  # }
}

# Azure Provider 기능 구성
provider "azurerm" {
  features {}
}

# 공통 태그 정의
locals {
  common_tags = merge(var.common_tags, {
    Environment = var.environment
    Project     = var.project_name
    CreatedBy   = "Terraform"
    CreatedDate = timestamp()
  })
}

# 기존 리소스 그룹 참조 (선택적)
data "azurerm_resource_group" "existing" {
  count = var.use_existing_resource_group ? 1 : 0
  name  = var.existing_resource_group_name
}

# 리소스 그룹 생성 (기존 리소스 그룹을 사용하지 않는 경우)
resource "azurerm_resource_group" "main" {
  count    = var.use_existing_resource_group ? 0 : 1
  name     = var.resource_group_name
  location = var.location

  tags = local.common_tags
}

# 실제 사용할 리소스 그룹 정보
locals {
  resource_group_name = var.use_existing_resource_group ? data.azurerm_resource_group.existing[0].name : azurerm_resource_group.main[0].name
  resource_group_location = var.use_existing_resource_group ? data.azurerm_resource_group.existing[0].location : azurerm_resource_group.main[0].location
}

# 네트워크 모듈
module "network" {
  source = "./modules/network"

  # 기본 설정
  resource_group_name = local.resource_group_name
  existing_vnet_name  = var.existing_vnet_name
  tags               = local.common_tags

  # 공용 IP 설정
  create_public_ip                = var.create_public_ip
  create_linux_pip               = var.create_linux_pip
  create_windows_pip             = var.create_windows_pip
  public_ip_name_prefix          = var.public_ip_name_prefix
  public_ip_allocation_method    = var.public_ip_allocation_method
  public_ip_sku                  = var.public_ip_sku
  public_ip_zones                = var.public_ip_zones
  public_ip_domain_name_label    = var.public_ip_domain_name_label
  public_ip_idle_timeout_in_minutes = var.public_ip_idle_timeout_in_minutes

  # 서브넷 설정
  use_existing_subnet            = var.use_existing_subnet
  existing_subnet_name           = var.existing_subnet_name
  create_new_subnet              = var.create_new_subnet
  subnet_count                   = var.subnet_count
  subnet_name_prefix             = var.subnet_name_prefix
  subnet_address_prefixes        = var.subnet_address_prefixes
  private_endpoint_network_policies_enabled = var.private_endpoint_network_policies_enabled
  private_link_service_network_policies_enabled = var.private_link_service_network_policies_enabled
  subnet_service_delegations     = var.subnet_service_delegations

  # NSG 설정 (기존 NSG 사용)
  use_existing_nsg               = var.use_existing_nsg
  existing_nsg_name              = var.existing_nsg_name
  associate_subnet_nsg           = var.associate_subnet_nsg
}

# 진단 설정 모듈
module "diagnostic" {
  count  = var.enable_diagnostic_settings ? 1 : 0
  source = "./modules/diagnostic"

  # 기본 설정
  resource_group_name = local.resource_group_name
  location            = local.resource_group_location
  tags               = local.common_tags

  # Log Analytics Workspace 설정
  use_existing_log_analytics_workspace = var.use_existing_log_analytics_workspace
  log_analytics_workspace_name         = var.log_analytics_workspace_name
  log_analytics_resource_group_name    = var.log_analytics_resource_group_name
  log_analytics_sku                    = var.log_analytics_sku
  log_analytics_retention_days         = var.log_analytics_retention_days

  # Storage Account 설정
  create_storage_account                = var.create_diagnostic_storage_account
  storage_account_name                  = var.diagnostic_storage_account_name
  storage_account_tier                  = "Standard"
  storage_account_replication_type      = "LRS"
  storage_account_kind                  = "StorageV2"

  # Action Group 설정
  create_action_group                   = var.create_diagnostic_action_group
  action_group_name                     = var.diagnostic_action_group_name
  action_group_short_name               = "diag-ag"

  # 대상 리소스 설정 (VM과 네트워크 리소스)
  target_resources = merge(
    # VM 리소스 진단 설정
    var.create_linux_vm ? {
      "linux-vm" = {
        name        = "linux-vm-diagnostic"
        resource_id = module.linux_vm.linux_vm_ids[0]
        enabled_logs = [
          {
            category         = "Administrative"
            retention_enabled = true
            retention_days   = var.log_analytics_retention_days
          },
          {
            category         = "Security"
            retention_enabled = true
            retention_days   = var.log_analytics_retention_days
          },
          {
            category         = "ServiceHealth"
            retention_enabled = true
            retention_days   = var.log_analytics_retention_days
          }
        ]
        enabled_metrics = [
          {
            category         = "AllMetrics"
            enabled          = true
            retention_enabled = true
            retention_days   = var.log_analytics_retention_days
          }
        ]
      }
    } : {},
    var.create_windows_vm ? {
      "windows-vm" = {
        name        = "windows-vm-diagnostic"
        resource_id = module.windows_vm.windows_vm_ids[0]
        enabled_logs = [
          {
            category         = "Administrative"
            retention_enabled = true
            retention_days   = var.log_analytics_retention_days
          },
          {
            category         = "Security"
            retention_enabled = true
            retention_days   = var.log_analytics_retention_days
          },
          {
            category         = "ServiceHealth"
            retention_enabled = true
            retention_days   = var.log_analytics_retention_days
          }
        ]
        enabled_metrics = [
          {
            category         = "AllMetrics"
            enabled          = true
            retention_enabled = true
            retention_days   = var.log_analytics_retention_days
          }
        ]
      }
    } : {},
    # 네트워크 리소스 진단 설정
    var.create_public_ip ? {
      "public-ip" = {
        name        = "public-ip-diagnostic"
        resource_id = module.network.public_ip_ids[0]
        enabled_logs = []
        enabled_metrics = [
          {
            category         = "AllMetrics"
            enabled          = true
            retention_enabled = true
            retention_days   = var.log_analytics_retention_days
          }
        ]
      }
    } : {}
  )
}


# Linux VM 모듈
module "linux_vm" {
  source = "./modules/linux-vm"

  # 기본 설정
  vm_name_prefix      = var.vm_name_prefix
  linux_vm_names      = var.linux_vm_names
  resource_group_name = local.resource_group_name
  location            = local.resource_group_location
  
  # VM 생성 제어
  linux_vm_count      = var.create_linux_vm ? var.linux_vm_count : 0
  
  # VM 크기 및 스토리지
  linux_vm_size               = var.linux_vm_size
  linux_storage_account_type  = var.linux_storage_account_type
  os_disk_size_gb             = var.os_disk_size_gb
  
  # 관리자 계정
  admin_username       = var.admin_username
  admin_password       = var.admin_password
  ssh_public_key       = var.ssh_public_key
  
  # 네트워킹 (네트워크 모듈 참조)
  subnet_id                   = module.network.subnet_id
  nsg_id                      = module.network.nsg_id
  existing_vnet_name          = var.existing_vnet_name
  existing_subnet_name        = module.network.subnet_name
  existing_nsg_name           = null  # 새로 생성하는 NSG이므로 null로 설정
  linux_public_ip_id          = module.network.linux_public_ip_id
  
  # 이미지 설정
  linux_vm_image_publisher = var.linux_vm_image_publisher
  linux_vm_image_offer     = var.linux_vm_image_offer
  linux_vm_image_sku       = var.linux_vm_image_sku
  linux_vm_image_version   = var.linux_vm_image_version
  
  # 가용성 설정
  availability_set_id         = var.availability_set_id
  availability_zone           = var.availability_zone
  enable_boot_diagnostics     = var.enable_boot_diagnostics
  boot_diagnostics_storage_account_uri = var.boot_diagnostics_storage_account_uri
  
  # 데이터 디스크 설정 - 사용하지 않음
  
  # VM 확장
  install_vm_extensions       = var.install_vm_extensions
  linux_vm_extensions         = var.linux_vm_extensions
  
  # Azure CLI 설치 설정
  install_azure_cli   = var.install_azure_cli
  custom_script_linux = var.custom_script_linux
  
  # 관리 ID 설정
  enable_managed_identity     = var.enable_managed_identity
  managed_identity_type       = var.managed_identity_type
  user_assigned_identity_ids  = var.user_assigned_identity_ids
  role_assignments            = var.role_assignments

  tags = local.common_tags
}

# Windows VM 모듈
module "windows_vm" {
  source = "./modules/windows-vm"

  # 기본 설정
  vm_name_prefix      = var.vm_name_prefix
  windows_vm_names    = var.windows_vm_names
  resource_group_name = local.resource_group_name
  location            = local.resource_group_location
  
  # VM 생성 제어
  windows_vm_count    = var.create_windows_vm ? var.windows_vm_count : 0
  
  # VM 크기 및 스토리지
  windows_vm_size             = var.windows_vm_size
  windows_storage_account_type = var.windows_storage_account_type
  os_disk_size_gb             = var.os_disk_size_gb
  
  # 관리자 계정
  admin_username = var.admin_username
  admin_password = var.admin_password
  
  # 네트워킹 (네트워크 모듈 참조)
  subnet_id                   = module.network.subnet_id
  nsg_id                      = module.network.nsg_id
  existing_vnet_name          = var.existing_vnet_name
  existing_subnet_name        = module.network.subnet_name
  existing_nsg_name           = null  # 새로 생성하는 NSG이므로 null로 설정
  windows_public_ip_id        = module.network.windows_public_ip_id
  
  # 이미지 설정
  windows_vm_image_publisher = var.windows_vm_image_publisher
  windows_vm_image_offer     = var.windows_vm_image_offer
  windows_vm_image_sku       = var.windows_vm_image_sku
  windows_vm_image_version   = var.windows_vm_image_version
  
  # 가용성 설정
  availability_set_id         = var.availability_set_id
  availability_zone           = var.availability_zone
  enable_boot_diagnostics     = var.enable_boot_diagnostics
  boot_diagnostics_storage_account_uri = var.boot_diagnostics_storage_account_uri
  
  # 데이터 디스크 설정 - 사용하지 않음
  
  # VM 확장
  install_vm_extensions       = var.install_vm_extensions
  windows_vm_extensions       = var.windows_vm_extensions
  
  # Azure CLI 설치 설정
  install_azure_cli     = var.install_azure_cli
  custom_script_windows = var.custom_script_windows
  
  # 관리 ID 설정
  enable_managed_identity     = var.enable_managed_identity
  managed_identity_type       = var.managed_identity_type
  user_assigned_identity_ids  = var.user_assigned_identity_ids
  role_assignments            = var.role_assignments

  tags = local.common_tags
}