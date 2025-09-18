# Windows Server 2022 Datacenter CI/CD 서버 스펙 설정 - poc
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
existing_resource_group_name = "rg-az01-poc-hyundai.teams-01"

# 기존 네트워킹 리소스 이름으로 설정
existing_vnet_name = "ict-poc-kttranslator-vnet-kc"
existing_subnet_name = "subnet-computing"
existing_nsg_name = "ict-poc-kttranslator-nsg-kc-compute"

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
windows_vm_size = "Standard_D4s_v3"  # 4 vCPU, 16 GiB RAM
linux_vm_size = "Standard_D4s_v3"    # 4 vCPU, 16 GiB RAM (Linux도 동일 스펙)
windows_storage_account_type = "Premium_LRS"  # Premium SSD
linux_storage_account_type = "Premium_LRS"    # Premium SSD

# OS 디스크 크기 - 128 GiB
os_disk_size_gb = 128

# 데이터 디스크 설정 - 32 GiB Premium SSD
create_data_disk = true
data_disk_size_gb = 32
data_disk_storage_account_type = "Premium_LRS"
data_disk_caching = "ReadWrite"
data_disk_lun = 0

# 관리자 계정
admin_username = "cjs"
admin_password = "cjsvm1234!!!"  # 강력한 비밀번호 설정

# ========================================
# 네트워킹 설정 - 기존 인프라 활용
# ========================================
create_public_ip = true
public_ip_allocation_method = "Static"
public_ip_sku = "Standard"

# 기존 NSG 사용 (이름으로 지정 가능)
# existing_nsg_name = "your-existing-nsg-name"

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
# Azure CLI 및 도구 설치 설정
# ========================================
install_azure_cli = true  # VM 생성 시 Azure CLI, .NET SDK, Docker 자동 설치

# ========================================
# 관리 ID 설정
# ========================================
enable_managed_identity = true
managed_identity_type = "SystemAssigned"

# VM 관리 ID에 할당할 역할들
role_assignments = {
  "custom_teams_ai_role" = {
    role_definition_name = "Custom-Role-poc-Teams-AI"
    scope               = "/subscriptions/d69e62aa-ef39-4bc0-b745-57ebc2bddcc8/resourceGroups/rg-az01-poc-hyundai.teams-01"
  }
  "storage_access" = {
    role_definition_name = "Storage Blob Data Contributor"
    scope               = "/subscriptions/d69e62aa-ef39-4bc0-b745-57ebc2bddcc8/resourceGroups/rg-az01-poc-hyundai.teams-01"
  }
}

# ========================================
# 고급 설정
# ========================================
enable_boot_diagnostics = true
