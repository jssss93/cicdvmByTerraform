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
  disable_password_authentication = var.disable_password_authentication
  ssh_public_key       = var.ssh_public_key
  
  # 네트워킹
  subnet_id                   = var.subnet_id
  nsg_id                      = var.nsg_id
  existing_vnet_name          = var.existing_vnet_name
  existing_subnet_name        = var.existing_subnet_name
  existing_nsg_name           = var.existing_nsg_name
  create_public_ip            = var.create_public_ip
  public_ip_allocation_method = var.public_ip_allocation_method
  public_ip_sku               = var.public_ip_sku
  
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
  
  # 데이터 디스크 설정
  create_data_disk            = var.create_data_disk
  data_disk_size_gb           = var.data_disk_size_gb
  data_disk_storage_account_type = var.data_disk_storage_account_type
  data_disk_caching           = var.data_disk_caching
  data_disk_lun               = var.data_disk_lun
  
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
  
  # 네트워킹
  subnet_id                   = var.subnet_id
  nsg_id                      = var.nsg_id
  existing_vnet_name          = var.existing_vnet_name
  existing_subnet_name        = var.existing_subnet_name
  existing_nsg_name           = var.existing_nsg_name
  create_public_ip            = var.create_public_ip
  public_ip_allocation_method = var.public_ip_allocation_method
  public_ip_sku               = var.public_ip_sku
  
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
  
  # 데이터 디스크 설정
  create_data_disk            = var.create_data_disk
  data_disk_size_gb           = var.data_disk_size_gb
  data_disk_storage_account_type = var.data_disk_storage_account_type
  data_disk_caching           = var.data_disk_caching
  data_disk_lun               = var.data_disk_lun
  
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