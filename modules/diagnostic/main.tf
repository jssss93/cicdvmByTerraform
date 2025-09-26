# Azure Diagnostic Settings 모듈
# 리소스별 진단 설정 생성 및 관리

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# 기존 Log Analytics Workspace 참조
data "azurerm_log_analytics_workspace" "existing" {
  count               = var.use_existing_log_analytics_workspace ? 1 : 0
  name                = var.log_analytics_workspace_name
  resource_group_name = var.log_analytics_resource_group_name
}

# Log Analytics Workspace 생성 (기존 사용하지 않는 경우)
resource "azurerm_log_analytics_workspace" "main" {
  count               = var.use_existing_log_analytics_workspace ? 0 : 1
  name                = var.log_analytics_workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_analytics_retention_days

  tags = var.tags
}

# Storage Account 생성 (선택적)
resource "azurerm_storage_account" "diagnostic" {
  count                    = var.create_storage_account ? 1 : 0
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type
  account_kind             = var.storage_account_kind

  tags = var.tags
}

# 진단 설정 생성
resource "azurerm_monitor_diagnostic_setting" "main" {
  for_each = var.target_resources

  name               = each.value.name
  target_resource_id = each.value.resource_id
  log_analytics_workspace_id = var.use_existing_log_analytics_workspace ? data.azurerm_log_analytics_workspace.existing[0].id : azurerm_log_analytics_workspace.main[0].id

  # Storage Account 설정은 별도로 관리

  # 로그 설정
  dynamic "enabled_log" {
    for_each = each.value.enabled_logs
    content {
      category = enabled_log.value.category
      category_group = enabled_log.value.category_group
      
      dynamic "retention_policy" {
        for_each = enabled_log.value.retention_enabled ? [1] : []
        content {
          enabled = true
          days    = enabled_log.value.retention_days
        }
      }
    }
  }

  # 메트릭 설정
  dynamic "metric" {
    for_each = each.value.enabled_metrics
    content {
      category = metric.value.category
      enabled  = metric.value.enabled
      
      dynamic "retention_policy" {
        for_each = metric.value.retention_enabled ? [1] : []
        content {
          enabled = true
          days    = metric.value.retention_days
        }
      }
    }
  }
}

# Action Group 생성 (선택적)
resource "azurerm_monitor_action_group" "main" {
  count               = var.create_action_group ? 1 : 0
  name                = var.action_group_name
  resource_group_name = var.resource_group_name
  short_name          = var.action_group_short_name



  tags = var.tags
}
