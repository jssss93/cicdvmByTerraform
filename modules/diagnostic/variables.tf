# Azure Diagnostic Settings 모듈 변수

# ========================================
# 기본 설정
# ========================================
variable "resource_group_name" {
  description = "리소스 그룹 이름"
  type        = string
}

variable "location" {
  description = "Azure 지역"
  type        = string
}

variable "tags" {
  description = "진단 설정 리소스에 적용할 태그"
  type        = map(string)
  default     = {}
}

# ========================================
# Log Analytics Workspace 설정
# ========================================
variable "use_existing_log_analytics_workspace" {
  description = "기존 Log Analytics Workspace 사용 여부"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_name" {
  description = "Log Analytics Workspace 이름"
  type        = string
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

# ========================================
# Storage Account 설정
# ========================================
variable "create_storage_account" {
  description = "진단용 Storage Account 생성 여부"
  type        = bool
  default     = false
}

variable "storage_account_name" {
  description = "Storage Account 이름"
  type        = string
  default     = null
}

variable "storage_account_tier" {
  description = "Storage Account 계층"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Standard", "Premium"], var.storage_account_tier)
    error_message = "계층은 Standard 또는 Premium이어야 합니다."
  }
}

variable "storage_account_replication_type" {
  description = "Storage Account 복제 유형"
  type        = string
  default     = "LRS"
  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.storage_account_replication_type)
    error_message = "복제 유형은 LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS 중 하나여야 합니다."
  }
}

variable "storage_account_kind" {
  description = "Storage Account 종류"
  type        = string
  default     = "StorageV2"
  validation {
    condition     = contains(["Storage", "StorageV2", "BlobStorage", "FileStorage", "BlockBlobStorage"], var.storage_account_kind)
    error_message = "종류는 Storage, StorageV2, BlobStorage, FileStorage, BlockBlobStorage 중 하나여야 합니다."
  }
}

# ========================================
# 진단 설정 대상 리소스
# ========================================
variable "target_resources" {
  description = "진단 설정을 적용할 대상 리소스들"
  type = map(object({
    name        = string
    resource_id = string
    enabled_logs = list(object({
      category      = string
      category_group = optional(string)
      retention_enabled = optional(bool, false)
      retention_days    = optional(number, 30)
    }))
    enabled_metrics = list(object({
      category      = string
      enabled       = bool
      retention_enabled = optional(bool, false)
      retention_days    = optional(number, 30)
    }))
  }))
  default = {}
}

# ========================================
# Action Group 설정
# ========================================
variable "create_action_group" {
  description = "Action Group 생성 여부"
  type        = bool
  default     = false
}

variable "action_group_name" {
  description = "Action Group 이름"
  type        = string
  default     = "diagnostic-action-group"
}

variable "action_group_short_name" {
  description = "Action Group 짧은 이름"
  type        = string
  default     = "diag-ag"
  validation {
    condition     = length(var.action_group_short_name) <= 12
    error_message = "짧은 이름은 12자 이하여야 합니다."
  }
}


