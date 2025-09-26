# 완전 변수화된 Azure VM Terraform 프로젝트 변수

# ========================================
# 기본 설정
# ========================================
variable "environment" {
  description = "환경 (dev, poc)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "poc"], var.environment)
    error_message = "환경은 dev, poc 중 하나여야 합니다."
  }
}

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = "terraform-azure-vms"
}

variable "location" {
  description = "Azure 지역"
  type        = string
  default     = "Korea Central"
}

variable "common_tags" {
  description = "모든 리소스에 적용할 공통 태그"
  type        = map(string)
  default     = {}
}

# ========================================
# 기존 리소스 사용 설정
# ========================================
variable "use_existing_resource_group" {
  description = "기존 리소스 그룹 사용 여부"
  type        = bool
  default     = false
}

variable "existing_resource_group_name" {
  description = "기존 리소스 그룹 이름"
  type        = string
  default     = ""
}


# ========================================
# 새 리소스 설정
# ========================================
variable "resource_group_name" {
  description = "리소스 그룹 이름 (새로 생성시)"
  type        = string
  default     = "rg-terraform-vms"
}

# ========================================

# ========================================
# 네트워킹 설정 (기존 리소스 사용)
# ========================================
variable "subnet_id" {
  description = "기존 서브넷 ID (직접 지정)"
  type        = string
  default     = null
}

variable "nsg_id" {
  description = "기존 Network Security Group ID (직접 지정)"
  type        = string
  default     = null
}

# 기존 네트워킹 리소스 이름 (ID 대신 이름으로 조회)
variable "existing_vnet_name" {
  description = "기존 Virtual Network 이름"
  type        = string
  default     = null
}

variable "existing_subnet_name" {
  description = "기존 서브넷 이름"
  type        = string
  default     = null
}

variable "existing_nsg_name" {
  description = "기존 Network Security Group 이름"
  type        = string
  default     = null
}


# ========================================
# 가상머신 기본 설정
# ========================================
variable "vm_name_prefix" {
  description = "VM 이름 접두사"
  type        = string
  default     = "vm-terraform"
}

variable "windows_vm_names" {
  description = "Windows VM 이름 목록 (지정하지 않으면 접두사 + 번호 사용)"
  type        = list(string)
  default     = []
}

variable "linux_vm_names" {
  description = "Linux VM 이름 목록 (지정하지 않으면 접두사 + 번호 사용)"
  type        = list(string)
  default     = []
}

variable "create_windows_vm" {
  description = "Windows VM 생성 여부"
  type        = bool
  default     = true
}

variable "create_linux_vm" {
  description = "Linux VM 생성 여부"
  type        = bool
  default     = true
}

variable "windows_vm_count" {
  description = "생성할 Windows VM 개수"
  type        = number
  default     = 1
  validation {
    condition     = var.windows_vm_count >= 0 && var.windows_vm_count <= 10
    error_message = "Windows VM 개수는 0-10 사이여야 합니다."
  }
}

variable "linux_vm_count" {
  description = "생성할 Linux VM 개수"
  type        = number
  default     = 1
  validation {
    condition     = var.linux_vm_count >= 0 && var.linux_vm_count <= 10
    error_message = "Linux VM 개수는 0-10 사이여야 합니다."
  }
}

# ========================================
# VM 크기 및 스토리지 설정
# ========================================
variable "windows_vm_size" {
  description = "Windows VM 크기"
  type        = string
  default     = "Standard_B2s"
}

variable "linux_vm_size" {
  description = "Linux VM 크기"
  type        = string
  default     = "Standard_B2s"
}

variable "vm_size" {
  description = "기본 VM 크기 (하위 호환성)"
  type        = string
  default     = "Standard_B2s"
}

variable "windows_storage_account_type" {
  description = "Windows VM 스토리지 계정 유형"
  type        = string
  default     = "Premium_LRS"
  validation {
    condition     = contains(["Standard_LRS", "StandardSSD_LRS", "Premium_LRS"], var.windows_storage_account_type)
    error_message = "스토리지 계정 유형은 Standard_LRS, StandardSSD_LRS, Premium_LRS 중 하나여야 합니다."
  }
}

variable "linux_storage_account_type" {
  description = "Linux VM 스토리지 계정 유형"
  type        = string
  default     = "Premium_LRS"
  validation {
    condition     = contains(["Standard_LRS", "StandardSSD_LRS", "Premium_LRS"], var.linux_storage_account_type)
    error_message = "스토리지 계정 유형은 Standard_LRS, StandardSSD_LRS, Premium_LRS 중 하나여야 합니다."
  }
}

variable "storage_account_type" {
  description = "기본 스토리지 계정 유형 (하위 호환성)"
  type        = string
  default     = "Premium_LRS"
}

variable "os_disk_size_gb" {
  description = "OS 디스크 크기 (GB)"
  type        = number
  default     = null
}

# ========================================
# 데이터 디스크 설정
# ========================================
# 데이터 디스크 설정 - 사용하지 않음

# ========================================
# 관리자 계정 설정
# ========================================
variable "admin_username" {
  description = "VM 관리자 사용자 이름"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "VM 관리자 비밀번호 (필수)"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.admin_password) >= 12
    error_message = "비밀번호는 최소 12자 이상이어야 합니다."
  }
}

variable "ssh_public_key" {
  description = "Linux VM SSH 공개 키"
  type        = string
  default     = null
}

# ========================================
# 네트워킹 설정
# ========================================
variable "create_public_ip" {
  description = "공용 IP 생성 여부"
  type        = bool
  default     = true
}


variable "public_ip_name_prefix" {
  description = "공용 IP 이름 접두사"
  type        = string
  default     = "pip"
}

variable "public_ip_allocation_method" {
  description = "공용 IP 할당 방법 (Static/Dynamic)"
  type        = string
  default     = "Static"
  validation {
    condition     = contains(["Static", "Dynamic"], var.public_ip_allocation_method)
    error_message = "공용 IP 할당 방법은 Static 또는 Dynamic이어야 합니다."
  }
}

variable "public_ip_sku" {
  description = "공용 IP SKU (Basic/Standard)"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Basic", "Standard"], var.public_ip_sku)
    error_message = "공용 IP SKU는 Basic 또는 Standard여야 합니다."
  }
}

variable "public_ip_zones" {
  description = "가용성 영역 목록"
  type        = list(string)
  default     = []
}

variable "public_ip_domain_name_label" {
  description = "도메인 이름 라벨 (선택적)"
  type        = string
  default     = null
}

variable "public_ip_idle_timeout_in_minutes" {
  description = "유휴 시간 초과 (분)"
  type        = number
  default     = 4
  validation {
    condition     = var.public_ip_idle_timeout_in_minutes >= 4 && var.public_ip_idle_timeout_in_minutes <= 30
    error_message = "유휴 시간 초과는 4-30분 사이여야 합니다."
  }
}

# ========================================
# 서브넷 설정
# ========================================
variable "use_existing_subnet" {
  description = "기존 서브넷 사용 여부"
  type        = bool
  default     = true
}

variable "create_new_subnet" {
  description = "새 서브넷 생성 여부"
  type        = bool
  default     = false
}

variable "subnet_count" {
  description = "생성할 서브넷 개수"
  type        = number
  default     = 1
  validation {
    condition     = var.subnet_count >= 0 && var.subnet_count <= 10
    error_message = "서브넷 개수는 0-10 사이여야 합니다."
  }
}

variable "subnet_name_prefix" {
  description = "서브넷 이름 접두사"
  type        = string
  default     = "subnet"
}

variable "subnet_address_prefixes" {
  description = "서브넷 주소 범위 목록 (CIDR)"
  type        = list(string)
  default     = []
  validation {
    condition = alltrue([
      for prefix in var.subnet_address_prefixes : can(cidrhost(prefix, 0))
    ])
    error_message = "모든 주소 범위는 유효한 CIDR 형식이어야 합니다 (예: 100.0.0.176/28)."
  }
}

variable "private_endpoint_network_policies_enabled" {
  description = "프라이빗 엔드포인트 네트워크 정책 활성화 여부"
  type        = bool
  default     = false
}

variable "private_link_service_network_policies_enabled" {
  description = "프라이빗 링크 서비스 네트워크 정책 활성화 여부"
  type        = bool
  default     = true
}

variable "subnet_service_delegations" {
  description = "서브넷에 적용할 서비스 위임 목록"
  type = list(object({
    name         = string
    service_name = string
    actions      = list(string)
  }))
  default = []
}

# ========================================
# NSG 설정
# ========================================
variable "use_existing_nsg" {
  description = "기존 NSG 사용 여부"
  type        = bool
  default     = true
}

variable "create_new_nsg" {
  description = "새 NSG 생성 여부"
  type        = bool
  default     = false
}

variable "nsg_name" {
  description = "NSG 이름"
  type        = string
  default     = "nsg"
}

variable "nsg_security_rules" {
  description = "NSG 보안 규칙 목록"
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  default = []
}

variable "associate_subnet_nsg" {
  description = "서브넷과 NSG 연결 여부"
  type        = bool
  default     = true
}

# ========================================
# 이미지 설정
# ========================================

# Windows VM 마켓플레이스 이미지 설정
variable "windows_vm_image_publisher" {
  description = "Windows VM 마켓플레이스 이미지 게시자"
  type        = string
  default     = "MicrosoftWindowsServer"
}

variable "windows_vm_image_offer" {
  description = "Windows VM 마켓플레이스 이미지 제안"
  type        = string
  default     = "WindowsServer"
}

variable "windows_vm_image_sku" {
  description = "Windows VM 마켓플레이스 이미지 SKU"
  type        = string
  default     = "2022-datacenter-g2"
}

variable "windows_vm_image_version" {
  description = "Windows VM 마켓플레이스 이미지 버전"
  type        = string
  default     = "latest"
}

# Linux VM 마켓플레이스 이미지 설정
variable "linux_vm_image_publisher" {
  description = "Linux VM 마켓플레이스 이미지 게시자"
  type        = string
  default     = "Canonical"
}

variable "linux_vm_image_offer" {
  description = "Linux VM 마켓플레이스 이미지 제안"
  type        = string
  default     = "0001-com-ubuntu-server-noble"
}

variable "linux_vm_image_sku" {
  description = "Linux VM 마켓플레이스 이미지 SKU"
  type        = string
  default     = "24_04-lts-gen2"
}

variable "linux_vm_image_version" {
  description = "Linux VM 마켓플레이스 이미지 버전"
  type        = string
  default     = "latest"
}

# ========================================
# 가용성 설정
# ========================================
variable "availability_set_id" {
  description = "가용성 세트 ID (선택적)"
  type        = string
  default     = null
}

variable "availability_zone" {
  description = "가용성 영역 (선택적)"
  type        = string
  default     = null
}

# ========================================
# 부팅 진단 설정
# ========================================
variable "enable_boot_diagnostics" {
  description = "부팅 진단 활성화 여부"
  type        = bool
  default     = true
}

variable "boot_diagnostics_storage_account_uri" {
  description = "부팅 진단 스토리지 계정 URI (null이면 관리 스토리지 사용)"
  type        = string
  default     = null
}

# ========================================
# VM 확장 설정
# ========================================
variable "install_vm_extensions" {
  description = "VM 확장 설치 여부"
  type        = bool
  default     = false
}

variable "windows_vm_extensions" {
  description = "Windows VM에 설치할 확장들"
  type = map(object({
    publisher            = string
    type                = string
    type_handler_version = string
    settings            = map(any)
    protected_settings  = map(any)
  }))
  default = {}
}

variable "linux_vm_extensions" {
  description = "Linux VM에 설치할 확장들"
  type = map(object({
    publisher            = string
    type                = string
    type_handler_version = string
    settings            = map(any)
    protected_settings  = map(any)
  }))
  default = {}
}

# ========================================
# ========================================
# Azure CLI 설치 설정
# ========================================
variable "install_azure_cli" {
  description = "VM 생성 시 Azure CLI 자동 설치 여부"
  type        = bool
  default     = true
}

variable "custom_script_windows" {
  description = "Windows VM에서 실행할 추가 PowerShell 스크립트"
  type        = string
  default     = ""
}

variable "custom_script_linux" {
  description = "Linux VM에서 실행할 추가 bash 스크립트"
  type        = string
  default     = ""
}

# ========================================
# 관리 ID 설정
# ========================================
variable "enable_managed_identity" {
  description = "VM에 관리 ID 활성화 여부"
  type        = bool
  default     = true
}

variable "managed_identity_type" {
  description = "관리 ID 유형 (SystemAssigned, UserAssigned, SystemAssigned,UserAssigned)"
  type        = string
  default     = "SystemAssigned"
  validation {
    condition     = contains(["SystemAssigned", "UserAssigned", "SystemAssigned,UserAssigned"], var.managed_identity_type)
    error_message = "관리 ID 유형은 SystemAssigned, UserAssigned, 또는 SystemAssigned,UserAssigned 중 하나여야 합니다."
  }
}

variable "user_assigned_identity_ids" {
  description = "사용자 할당 관리 ID 목록 (UserAssigned 사용 시)"
  type        = list(string)
  default     = []
}

variable "role_assignments" {
  description = "VM 관리 ID에 할당할 역할들"
  type = map(object({
    role_definition_name = string
    scope               = string
  }))
  default = {}
}

# ========================================
# 하위 호환성 (기존 변수들)
# ========================================
variable "allowed_ip_ranges" {
  description = "접근을 허용할 IP 범위 목록 (사용되지 않음 - security_rules 사용)"
  type        = list(string)
  default     = ["*"]
}

# ========================================
# 진단 설정 (Diagnostic Settings)
# ========================================
variable "enable_diagnostic_settings" {
  description = "VM 진단 설정 활성화 여부"
  type        = bool
  default     = false
}


variable "diagnostic_logs_categories" {
  description = "수집할 진단 로그 카테고리 목록"
  type        = list(string)
  default     = [
    "Administrative",
    "Security", 
    "ServiceHealth",
    "Alert",
    "Recommendation",
    "Policy",
    "Autoscale",
    "ResourceHealth"
  ]
}

variable "diagnostic_metrics_categories" {
  description = "수집할 진단 메트릭 카테고리 목록"
  type        = list(string)
  default     = [
    "AllMetrics"
  ]
}

variable "diagnostic_retention_days" {
  description = "진단 로그 보존 기간 (일)"
  type        = number
  default     = 30
}

# ========================================
# Azure Automation 설정
# ========================================
variable "use_automation_for_setup" {
  description = "Azure Automation을 사용한 VM 설정 여부"
  type        = bool
  default     = true
}

variable "automation_account_name" {
  description = "Azure Automation Account 이름 (기본값: 자동 생성)"
  type        = string
  default     = null
}

# ========================================
# 진단 설정 (Diagnostic Settings) - 추가 설정
# ========================================
variable "use_existing_log_analytics_workspace" {
  description = "기존 Log Analytics Workspace 사용 여부"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_name" {
  description = "Log Analytics Workspace 이름"
  type        = string
  default     = null
}

variable "log_analytics_resource_group_name" {
  description = "Log Analytics Workspace가 있는 리소스 그룹 이름"
  type        = string
  default     = null
}

variable "log_analytics_sku" {
  description = "Log Analytics Workspace SKU"
  type        = string
  default     = "PerGB2018"
  validation {
    condition     = contains(["Free", "PerNode", "PerGB2018", "Standard", "Premium"], var.log_analytics_sku)
    error_message = "SKU는 Free, PerNode, PerGB2018, Standard, Premium 중 하나여야 합니다."
  }
}

variable "log_analytics_retention_days" {
  description = "Log Analytics Workspace 보존 기간 (일)"
  type        = number
  default     = 30
  validation {
    condition     = var.log_analytics_retention_days >= 30 && var.log_analytics_retention_days <= 730
    error_message = "보존 기간은 30-730일 사이여야 합니다."
  }
}

variable "create_diagnostic_storage_account" {
  description = "진단용 Storage Account 생성 여부"
  type        = bool
  default     = false
}

variable "diagnostic_storage_account_name" {
  description = "진단용 Storage Account 이름"
  type        = string
  default     = null
}

variable "create_diagnostic_action_group" {
  description = "진단용 Action Group 생성 여부"
  type        = bool
  default     = false
}

variable "diagnostic_action_group_name" {
  description = "진단용 Action Group 이름"
  type        = string
  default     = "diagnostic-action-group"
}

