# Azure Diagnostic Settings 모듈 출력

# ========================================
# Log Analytics Workspace 출력
# ========================================
output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  value = var.use_existing_log_analytics_workspace ? data.azurerm_log_analytics_workspace.existing[0].id : azurerm_log_analytics_workspace.main[0].id
}

output "log_analytics_workspace_name" {
  description = "Log Analytics Workspace 이름"
  value = var.use_existing_log_analytics_workspace ? data.azurerm_log_analytics_workspace.existing[0].name : azurerm_log_analytics_workspace.main[0].name
}

output "log_analytics_workspace_primary_shared_key" {
  description = "Log Analytics Workspace Primary Shared Key"
  value = var.use_existing_log_analytics_workspace ? data.azurerm_log_analytics_workspace.existing[0].primary_shared_key : azurerm_log_analytics_workspace.main[0].primary_shared_key
  sensitive = true
}

# ========================================
# Storage Account 출력
# ========================================
output "storage_account_id" {
  description = "Storage Account ID"
  value       = var.create_storage_account ? azurerm_storage_account.diagnostic[0].id : null
}

output "storage_account_name" {
  description = "Storage Account 이름"
  value       = var.create_storage_account ? azurerm_storage_account.diagnostic[0].name : null
}

output "storage_account_primary_access_key" {
  description = "Storage Account Primary Access Key"
  value       = var.create_storage_account ? azurerm_storage_account.diagnostic[0].primary_access_key : null
  sensitive   = true
}

# ========================================
# 진단 설정 출력
# ========================================
output "diagnostic_setting_ids" {
  description = "생성된 진단 설정 ID 목록"
  value       = { for k, v in azurerm_monitor_diagnostic_setting.main : k => v.id }
}

output "diagnostic_setting_names" {
  description = "생성된 진단 설정 이름 목록"
  value       = { for k, v in azurerm_monitor_diagnostic_setting.main : k => v.name }
}

# ========================================
# Action Group 출력
# ========================================
output "action_group_id" {
  description = "Action Group ID"
  value       = var.create_action_group ? azurerm_monitor_action_group.main[0].id : null
}

output "action_group_name" {
  description = "Action Group 이름"
  value       = var.create_action_group ? azurerm_monitor_action_group.main[0].name : null
}

# ========================================
# 진단 설정 요약
# ========================================
output "diagnostic_configuration" {
  description = "진단 설정 구성 정보"
  value = {
    log_analytics_workspace_name = var.use_existing_log_analytics_workspace ? data.azurerm_log_analytics_workspace.existing[0].name : azurerm_log_analytics_workspace.main[0].name
    storage_account_created = var.create_storage_account
    storage_account_name = var.create_storage_account ? azurerm_storage_account.diagnostic[0].name : null
    action_group_created = var.create_action_group
    action_group_name = var.create_action_group ? azurerm_monitor_action_group.main[0].name : null
    target_resources_count = length(var.target_resources)
    target_resources = keys(var.target_resources)
  }
}
