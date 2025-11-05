# Windows Server 2022 Datacenter CI/CD 서버 스펙 설정
# 코드 컴파일과 Docker 이미지 빌드를 위한 고성능 구성

# ========================================
# 기본 설정
# ========================================
environment = "poc"
location = "Korea Central"

# 공통 태그
common_tags = {
  CostCenter  = "KT AXD"
  Environment = "poc"
  ManagedBy   = "Terraform"
  Owner       = "JongsuChoi"
  Project     = "hyundai-teams-meeting-ai-translator-cicd"
}

use_existing_resource_group = true
existing_resource_group_name = "ict-poc-kttranslator-rg-kc"

# 기존 네트워킹 리소스 이름으로 설정
existing_vnet_name = "ict-poc-kttranslator-vnet-kc"
existing_subnet_name = "ict-poc-kttranslator-sbn-cicd-kc"

# ========================================
# VM 설정 - Windows Server 2022 CI/CD 서버 스펙
# ========================================
vm_name_prefix = "ict-poc-kttranslator-cicivm01-kc"

# VM 개별 이름 설정 (각 VM의 정확한 이름 지정)
windows_vm_names = ["ict-poc-kttranslator-winvm01-kc"]
linux_vm_names = ["ict-poc-kttranslator-linuxvm01-kc"]

create_windows_vm = true
create_linux_vm = true
windows_vm_count = 1
linux_vm_count = 1

# VM 크기 및 스토리지 - 고성능 스펙
windows_vm_size = "Standard_D2s_v3"  # 4 vCPU, 16 GiB RAM
linux_vm_size = "Standard_D2s_v3"    # 4 vCPU, 16 GiB RAM (Linux도 동일 스펙)
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
# 네트워크 설정 (poc 환경)
# ========================================
# 공용 IP 설정
create_public_ip = false
create_linux_pip = false
create_windows_pip = false
# PIP는 VM별로 개별 생성됨 (Linux, Windows 각각)
public_ip_name_prefix = "ict-poc-kttranslator-pip"
public_ip_allocation_method = "Static"
public_ip_sku = "Standard"

# 서브넷 설정 (기존 사용)
use_existing_subnet = true

# NSG 설정 (환경별)
use_existing_nsg = true
existing_nsg_name = "ict-poc-kttranslator-cicd-nsg-kc"
associate_subnet_nsg = true

# ========================================
# 진단 설정 (poc 환경)
# ========================================
enable_diagnostic_settings = true
use_existing_log_analytics_workspace = true
log_analytics_workspace_name = "ict-poc-kttranslator-law-kc"
log_analytics_resource_group_name = "ict-poc-kttranslator-rg-kc"
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
    scope = "/subscriptions/75e3ba05-c5dc-4b32-8509-37204d22ae9c/resourceGroups/ict-poc-kttranslator-rg-kc"
  }
  "acr-pull" = {
    role_definition_name = "AcrPull"
    scope = "/subscriptions/75e3ba05-c5dc-4b32-8509-37204d22ae9c/resourceGroups/ict-poc-kttranslator-rg-kc"
  }
  "acr-push" = {
    role_definition_name = "AcrPush"
    scope = "/subscriptions/75e3ba05-c5dc-4b32-8509-37204d22ae9c/resourceGroups/ict-poc-kttranslator-rg-kc"
  }
  "log-analytics-contributor" = {
    role_definition_name = "Log Analytics Contributor"
    scope = "/subscriptions/75e3ba05-c5dc-4b32-8509-37204d22ae9c/resourceGroups/ict-poc-kttranslator-rg-kc"
  }
  "monitoring-metrics-publisher" = {
    role_definition_name = "Monitoring Metrics Publisher"
    scope = "/subscriptions/75e3ba05-c5dc-4b32-8509-37204d22ae9c/resourceGroups/ict-poc-kttranslator-rg-kc"
  }
  "virtual-machine-contributor" = {
    role_definition_name = "Virtual Machine Contributor"
    scope = "/subscriptions/75e3ba05-c5dc-4b32-8509-37204d22ae9c/resourceGroups/ict-poc-kttranslator-rg-kc"
  }
  "network-contributor" = {
    role_definition_name = "Network Contributor"
    scope = "/subscriptions/75e3ba05-c5dc-4b32-8509-37204d22ae9c/resourceGroups/ict-poc-kttranslator-rg-kc"
  }
  "website-contributor" = {
    role_definition_name = "Website Contributor"
    scope = "/subscriptions/75e3ba05-c5dc-4b32-8509-37204d22ae9c/resourceGroups/ict-poc-kttranslator-rg-kc"
  }
}

# GitHub Actions Runner 설정
linux_github_runner_name = "linux-runner-poc-01"
windows_github_runner_name = "windows-runner-poc-01"

# Windows Custom Script Extension 설정
windows_custom_script_url = "https://ictpockttranslatorst02kc.blob.core.windows.net/scripts/install-windows-en.ps1?se=2025-12-31T23%3A59%3A59Z&sp=r&sv=2022-11-02&sr=b&sig=q5llmjI3Q8std%2F38ss77slNpck2O0UWnTEiIfYHFkoA%3D"
