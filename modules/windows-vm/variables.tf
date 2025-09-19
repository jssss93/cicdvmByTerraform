# Windows VM 모듈 변수

# 기본 설정
variable "vm_name_prefix" {
  description = "VM 이름 접두사"
  type        = string
  default     = "vm-windows"
}

variable "windows_vm_names" {
  description = "Windows VM 이름 목록 (지정하지 않으면 접두사 + 번호 사용)"
  type        = list(string)
  default     = []
}

variable "resource_group_name" {
  description = "리소스 그룹 이름"
  type        = string
}

variable "location" {
  description = "Azure 지역"
  type        = string
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

# VM 크기 및 스토리지
variable "windows_vm_size" {
  description = "Windows VM 크기"
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

variable "os_disk_size_gb" {
  description = "OS 디스크 크기 (GB)"
  type        = number
  default     = null
}

# 데이터 디스크 설정
variable "create_data_disk" {
  description = "데이터 디스크 생성 여부"
  type        = bool
  default     = false
}

variable "data_disk_size_gb" {
  description = "데이터 디스크 크기 (GB)"
  type        = number
  default     = 32
}

variable "data_disk_storage_account_type" {
  description = "데이터 디스크 스토리지 계정 유형"
  type        = string
  default     = "Premium_LRS"
}

variable "data_disk_caching" {
  description = "데이터 디스크 캐싱 설정"
  type        = string
  default     = "ReadWrite"
}

variable "data_disk_lun" {
  description = "데이터 디스크 LUN"
  type        = number
  default     = 0
}

# 관리자 계정 설정
variable "admin_username" {
  description = "VM 관리자 사용자 이름"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "VM 관리자 비밀번호 (지정하지 않으면 자동 생성)"
  type        = string
  default     = null
  sensitive   = true
}

# 네트워킹 설정
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

variable "create_public_ip" {
  description = "공용 IP 생성 여부"
  type        = bool
  default     = true
}

variable "public_ip_allocation_method" {
  description = "공용 IP 할당 방법"
  type        = string
  default     = "Static"
}

variable "public_ip_sku" {
  description = "공용 IP SKU"
  type        = string
  default     = "Standard"
}

# 이미지 설정
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

# 가용성 설정
variable "availability_set_id" {
  description = "가용성 세트 ID"
  type        = string
  default     = null
}

variable "availability_zone" {
  description = "가용성 영역"
  type        = string
  default     = null
}

# 부팅 진단 설정
variable "enable_boot_diagnostics" {
  description = "부팅 진단 활성화 여부"
  type        = bool
  default     = true
}

variable "boot_diagnostics_storage_account_uri" {
  description = "부팅 진단 스토리지 계정 URI"
  type        = string
  default     = null
}

# VM 확장 설정
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

# Azure CLI 설치 설정
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

# 관리 ID 설정
variable "enable_managed_identity" {
  description = "VM에 관리 ID 활성화 여부"
  type        = bool
  default     = true
}

variable "managed_identity_type" {
  description = "관리 ID 유형"
  type        = string
  default     = "SystemAssigned"
}

variable "user_assigned_identity_ids" {
  description = "사용자 할당 관리 ID 목록"
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

# 태그
variable "tags" {
  description = "리소스에 적용할 태그"
  type        = map(string)
  default     = {}
}
