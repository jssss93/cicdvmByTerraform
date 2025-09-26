# Azure Public IP 모듈 출력

# Linux VM용 공용 IP 출력
output "linux_public_ip_id" {
  description = "Linux VM용 공용 IP ID"
  value       = var.create_public_ip && var.create_linux_pip ? azurerm_public_ip.linux[0].id : null
}

output "linux_public_ip_address" {
  description = "Linux VM용 공용 IP 주소"
  value       = var.create_public_ip && var.create_linux_pip ? azurerm_public_ip.linux[0].ip_address : null
}

output "linux_public_ip_name" {
  description = "Linux VM용 공용 IP 이름"
  value       = var.create_public_ip && var.create_linux_pip ? azurerm_public_ip.linux[0].name : null
}

output "linux_public_ip_fqdn" {
  description = "Linux VM용 공용 IP FQDN"
  value       = var.create_public_ip && var.create_linux_pip ? azurerm_public_ip.linux[0].fqdn : null
}

# Windows VM용 공용 IP 출력
output "windows_public_ip_id" {
  description = "Windows VM용 공용 IP ID"
  value       = var.create_public_ip && var.create_windows_pip ? azurerm_public_ip.windows[0].id : null
}

output "windows_public_ip_address" {
  description = "Windows VM용 공용 IP 주소"
  value       = var.create_public_ip && var.create_windows_pip ? azurerm_public_ip.windows[0].ip_address : null
}

output "windows_public_ip_name" {
  description = "Windows VM용 공용 IP 이름"
  value       = var.create_public_ip && var.create_windows_pip ? azurerm_public_ip.windows[0].name : null
}

output "windows_public_ip_fqdn" {
  description = "Windows VM용 공용 IP FQDN"
  value       = var.create_public_ip && var.create_windows_pip ? azurerm_public_ip.windows[0].fqdn : null
}

# 통합 출력 (하위 호환성)
output "public_ip_ids" {
  description = "생성된 공용 IP ID 목록"
  value       = concat(
    var.create_public_ip && var.create_linux_pip ? [azurerm_public_ip.linux[0].id] : [],
    var.create_public_ip && var.create_windows_pip ? [azurerm_public_ip.windows[0].id] : []
  )
}

output "public_ip_addresses" {
  description = "생성된 공용 IP 주소 목록"
  value       = concat(
    var.create_public_ip && var.create_linux_pip ? [azurerm_public_ip.linux[0].ip_address] : [],
    var.create_public_ip && var.create_windows_pip ? [azurerm_public_ip.windows[0].ip_address] : []
  )
}

output "public_ip_names" {
  description = "생성된 공용 IP 이름 목록"
  value       = concat(
    var.create_public_ip && var.create_linux_pip ? [azurerm_public_ip.linux[0].name] : [],
    var.create_public_ip && var.create_windows_pip ? [azurerm_public_ip.windows[0].name] : []
  )
}

output "public_ip_fqdns" {
  description = "생성된 공용 IP FQDN 목록"
  value       = concat(
    var.create_public_ip && var.create_linux_pip ? [azurerm_public_ip.linux[0].fqdn] : [],
    var.create_public_ip && var.create_windows_pip ? [azurerm_public_ip.windows[0].fqdn] : []
  )
}

output "public_ip_resource_group_name" {
  description = "공용 IP가 속한 리소스 그룹 이름"
  value       = var.resource_group_name
}

# 단일 값 출력 (하위 호환성)
output "public_ip_id" {
  description = "첫 번째 공용 IP ID (하위 호환성)"
  value       = length(concat(
    var.create_public_ip && var.create_linux_pip ? [azurerm_public_ip.linux[0].id] : [],
    var.create_public_ip && var.create_windows_pip ? [azurerm_public_ip.windows[0].id] : []
  )) > 0 ? concat(
    var.create_public_ip && var.create_linux_pip ? [azurerm_public_ip.linux[0].id] : [],
    var.create_public_ip && var.create_windows_pip ? [azurerm_public_ip.windows[0].id] : []
  )[0] : null
}

output "public_ip_address" {
  description = "첫 번째 공용 IP 주소 (하위 호환성)"
  value       = length(concat(
    var.create_public_ip && var.create_linux_pip ? [azurerm_public_ip.linux[0].ip_address] : [],
    var.create_public_ip && var.create_windows_pip ? [azurerm_public_ip.windows[0].ip_address] : []
  )) > 0 ? concat(
    var.create_public_ip && var.create_linux_pip ? [azurerm_public_ip.linux[0].ip_address] : [],
    var.create_public_ip && var.create_windows_pip ? [azurerm_public_ip.windows[0].ip_address] : []
  )[0] : null
}

output "public_ip_name" {
  description = "첫 번째 공용 IP 이름 (하위 호환성)"
  value       = length(concat(
    var.create_public_ip && var.create_linux_pip ? [azurerm_public_ip.linux[0].name] : [],
    var.create_public_ip && var.create_windows_pip ? [azurerm_public_ip.windows[0].name] : []
  )) > 0 ? concat(
    var.create_public_ip && var.create_linux_pip ? [azurerm_public_ip.linux[0].name] : [],
    var.create_public_ip && var.create_windows_pip ? [azurerm_public_ip.windows[0].name] : []
  )[0] : null
}

output "public_ip_fqdn" {
  description = "첫 번째 공용 IP FQDN (하위 호환성)"
  value       = length(concat(
    var.create_public_ip && var.create_linux_pip ? [azurerm_public_ip.linux[0].fqdn] : [],
    var.create_public_ip && var.create_windows_pip ? [azurerm_public_ip.windows[0].fqdn] : []
  )) > 0 ? concat(
    var.create_public_ip && var.create_linux_pip ? [azurerm_public_ip.linux[0].fqdn] : [],
    var.create_public_ip && var.create_windows_pip ? [azurerm_public_ip.windows[0].fqdn] : []
  )[0] : null
}

# 프리픽스 출력
output "public_ip_prefix_id" {
  description = "공용 IP 프리픽스 ID"
  value       = var.create_public_ip_prefix ? azurerm_public_ip_prefix.main[0].id : null
}

output "public_ip_prefix_ip_prefix" {
  description = "공용 IP 프리픽스 범위"
  value       = var.create_public_ip_prefix ? azurerm_public_ip_prefix.main[0].ip_prefix : null
}
