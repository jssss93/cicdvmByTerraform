# Azure Public IP 모듈 변수

variable "resource_group_name" {
  description = "리소스 그룹 이름"
  type        = string
}

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
}

variable "allocation_method" {
  description = "IP 할당 방법 (Static/Dynamic)"
  type        = string
  default     = "Static"
  validation {
    condition     = contains(["Static", "Dynamic"], var.allocation_method)
    error_message = "할당 방법은 Static 또는 Dynamic이어야 합니다."
  }
}

variable "sku" {
  description = "공용 IP SKU (Basic/Standard)"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Basic", "Standard"], var.sku)
    error_message = "SKU는 Basic 또는 Standard여야 합니다."
  }
}

variable "availability_zones" {
  description = "가용성 영역 목록"
  type        = list(string)
  default     = []
}

variable "domain_name_label" {
  description = "도메인 이름 라벨 (선택적)"
  type        = string
  default     = null
}

variable "idle_timeout_in_minutes" {
  description = "유휴 시간 초과 (분)"
  type        = number
  default     = 4
  validation {
    condition     = var.idle_timeout_in_minutes >= 4 && var.idle_timeout_in_minutes <= 30
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

variable "tags" {
  description = "공용 IP에 적용할 태그"
  type        = map(string)
  default     = {}
}
