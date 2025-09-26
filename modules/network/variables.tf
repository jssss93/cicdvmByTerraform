# Azure Network 모듈 변수

# ========================================
# 기본 설정
# ========================================
variable "resource_group_name" {
  description = "리소스 그룹 이름"
  type        = string
}

variable "existing_vnet_name" {
  description = "기존 Virtual Network 이름"
  type        = string
}

variable "tags" {
  description = "네트워크 리소스에 적용할 태그"
  type        = map(string)
  default     = {}
}

# ========================================
# 공용 IP 설정
# ========================================
variable "create_public_ip" {
  description = "공용 IP 생성 여부"
  type        = bool
  default     = true
}

variable "create_linux_pip" {
  description = "Linux VM용 공용 IP 생성 여부"
  type        = bool
  default     = true
}

variable "create_windows_pip" {
  description = "Windows VM용 공용 IP 생성 여부"
  type        = bool
  default     = true
}

variable "public_ip_name_prefix" {
  description = "공용 IP 이름 접두사"
  type        = string
  default     = "pip"
}

variable "public_ip_allocation_method" {
  description = "IP 할당 방법 (Static/Dynamic)"
  type        = string
  default     = "Static"
  validation {
    condition     = contains(["Static", "Dynamic"], var.public_ip_allocation_method)
    error_message = "할당 방법은 Static 또는 Dynamic이어야 합니다."
  }
}

variable "public_ip_sku" {
  description = "공용 IP SKU (Basic/Standard)"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Basic", "Standard"], var.public_ip_sku)
    error_message = "SKU는 Basic 또는 Standard여야 합니다."
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

variable "create_public_ip_prefix" {
  description = "공용 IP 프리픽스 생성 여부"
  type        = bool
  default     = false
}

variable "public_ip_prefix_length" {
  description = "공용 IP 프리픽스 길이"
  type        = number
  default     = 28
  validation {
    condition     = var.public_ip_prefix_length >= 28 && var.public_ip_prefix_length <= 31
    error_message = "프리픽스 길이는 28-31 사이여야 합니다."
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

variable "existing_subnet_name" {
  description = "기존 서브넷 이름"
  type        = string
  default     = null
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

variable "existing_nsg_name" {
  description = "기존 NSG 이름"
  type        = string
  default     = null
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
