# Windows Server 2022 Datacenter CI/CD 서버 스펙 설정
# 코드 컴파일과 Docker 이미지 빌드를 위한 고성능 구성

# ========================================
# 기본 설정
# ========================================
environment = "dev"
location = "Korea Central"

# 공통 태그
common_tags = {
  Project     = "hyundai-teams-meeting-ai-translator-cicd"
  Environment = "dev"
  Owner       = "JongsuChoi"
  ManagedBy   = "Terraform"
  CostCenter  = "KT AXD"
}

use_existing_resource_group = true
existing_resource_group_name = "rg-az01-poc-hyundai.teams-01"

# 기존 네트워킹 리소스 이름으로 설정
existing_vnet_name = "ict-dev-kttranslator-vnet-kc"
existing_subnet_name = "subnet-computing"

# ========================================
# VM 설정 - Windows Server 2022 CI/CD 서버 스펙
# ========================================
vm_name_prefix = "ict-dev-kttranslator-cicivm01-kc"

# VM 개별 이름 설정 (각 VM의 정확한 이름 지정)
windows_vm_names = ["ict-dev-kttranslator-winvm01-kc"]
linux_vm_names = ["ict-dev-kttranslator-linuxvm01-kc"]

create_windows_vm = true
create_linux_vm = true
windows_vm_count = 1
linux_vm_count = 1

# VM 크기 및 스토리지 - 비용 최적화 스펙
windows_vm_size = "Standard_D2s_v3"  # 2 vCPU, 8 GiB RAM
linux_vm_size = "Standard_D2s_v3"    # 2 vCPU, 8 GiB RAM (Linux도 동일 스펙)
windows_storage_account_type = "Standard_LRS"  # Standard SSD
linux_storage_account_type = "Standard_LRS"    # Standard SSD

# OS 디스크 크기 - 128 GiB
os_disk_size_gb = 128

# 데이터 디스크 설정 - 사용하지 않음

# 관리자 계정
admin_username = "azureuser"
admin_password = "1q2w3e4r####"  # 필수: 최소 12자 이상

# ========================================
# 네트워킹 설정 - 기존 인프라 활용
# ========================================

# ========================================
# 이미지 설정 - Windows Server 2022 Datacenter
# ========================================

# Windows Server 2022 Datacenter 이미지 (원본 이미지 세부 정보 기준)
windows_vm_image_publisher = "MicrosoftWindowsServer"
windows_vm_image_offer = "WindowsServer"
windows_vm_image_sku = "2022-datacenter-azure-edition"
windows_vm_image_version = "latest"

# Ubuntu 24.04 LTS 이미지 (원본 이미지 세부 정보 기준)
linux_vm_image_publisher = "canonical"
linux_vm_image_offer = "ubuntu-24_04-lts"
linux_vm_image_sku = "server"
linux_vm_image_version = "latest"

# ========================================
# 고급 설정
# ========================================
enable_boot_diagnostics = true

# VM 확장 설치
install_vm_extensions = true

# ========================================
# 네트워크 설정 (dev 환경)
# ========================================
# 공용 IP 설정
create_public_ip = true
# PIP는 VM별로 개별 생성됨 (Linux, Windows 각각)
public_ip_name_prefix = "ict-dev-kttranslator-pip"
public_ip_allocation_method = "Static"
public_ip_sku = "Standard"

# 서브넷 설정 (기존 사용)
use_existing_subnet = true

# NSG 설정 (CI/CD용 새로 생성)
use_existing_nsg = false
create_new_nsg = true
nsg_name = "ict-dev-kttranslator-cicd-nsg-kc"
associate_subnet_nsg = true

# CI/CD용 NSG 보안 규칙 설정
nsg_security_rules = [
  {
    name                       = "AllowHTTPS"
    priority                   = 1030
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Allow HTTPS for secure web services"
  },
  {
    name                       = "AllowOutboundInternet"
    priority                   = 2000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
    description                = "Allow outbound internet access for CI/CD"
  }
]

# ========================================
# 진단 설정 (dev 환경)
# ========================================
enable_diagnostic_settings = true
use_existing_log_analytics_workspace = true
log_analytics_workspace_name = "ict-dev-kttranslator-law-kc"
log_analytics_resource_group_name = "rg-az01-poc-hyundai.teams-01"
log_analytics_retention_days = 30

# 진단용 Storage Account 생성 (선택적)
create_diagnostic_storage_account = false

# 진단용 Action Group 생성 (선택적)
create_diagnostic_action_group = false

# ========================================
# VM 관리 ID 역할 할당 설정
# ========================================
enable_managed_identity = true
managed_identity_type = "SystemAssigned"

# VM 관리 ID에 할당할 역할들
role_assignments = {
  "storage-blob-data-contributor" = {
    role_definition_name = "Storage Blob Data Contributor"
    scope = "/subscriptions/d69e62aa-ef39-4bc0-b745-57ebc2bddcc8/resourceGroups/rg-az01-poc-hyundai.teams-01"
  }
  "acr-pull" = {
    role_definition_name = "AcrPull"
    scope = "/subscriptions/d69e62aa-ef39-4bc0-b745-57ebc2bddcc8/resourceGroups/rg-az01-poc-hyundai.teams-01"
  }
  "log-analytics-contributor" = {
    role_definition_name = "Log Analytics Contributor"
    scope = "/subscriptions/d69e62aa-ef39-4bc0-b745-57ebc2bddcc8/resourceGroups/rg-az01-poc-hyundai.teams-01"
  }
  "monitoring-metrics-publisher" = {
    role_definition_name = "Monitoring Metrics Publisher"
    scope = "/subscriptions/d69e62aa-ef39-4bc0-b745-57ebc2bddcc8/resourceGroups/rg-az01-poc-hyundai.teams-01"
  }
  "virtual-machine-contributor" = {
    role_definition_name = "Virtual Machine Contributor"
    scope = "/subscriptions/d69e62aa-ef39-4bc0-b745-57ebc2bddcc8/resourceGroups/rg-az01-poc-hyundai.teams-01"
  }
  "network-contributor" = {
    role_definition_name = "Network Contributor"
    scope = "/subscriptions/d69e62aa-ef39-4bc0-b745-57ebc2bddcc8/resourceGroups/rg-az01-poc-hyundai.teams-01"
  }
}


