# 가상머신 모듈 출력 - 다중 VM 지원

# Windows VM 정보
output "windows_vm_ids" {
  description = "Windows VM ID 목록"
  value       = var.create_windows_vm ? azurerm_windows_virtual_machine.main[*].id : []
}

output "windows_vm_names" {
  description = "Windows VM 이름 목록"
  value       = var.create_windows_vm ? azurerm_windows_virtual_machine.main[*].name : []
}

output "windows_public_ips" {
  description = "Windows VM 공용 IP 주소 목록"
  value       = var.create_windows_vm && var.create_public_ip ? azurerm_public_ip.windows_vm[*].ip_address : []
}

output "windows_private_ips" {
  description = "Windows VM 사설 IP 주소 목록"
  value       = var.create_windows_vm ? azurerm_network_interface.windows_vm[*].private_ip_address : []
}

# Linux VM 정보
output "linux_vm_ids" {
  description = "Linux VM ID 목록"
  value       = var.create_linux_vm ? azurerm_linux_virtual_machine.main[*].id : []
}

output "linux_vm_names" {
  description = "Linux VM 이름 목록"
  value       = var.create_linux_vm ? azurerm_linux_virtual_machine.main[*].name : []
}

output "linux_public_ips" {
  description = "Linux VM 공용 IP 주소 목록"
  value       = var.create_linux_vm && var.create_public_ip ? azurerm_public_ip.linux_vm[*].ip_address : []
}

output "linux_private_ips" {
  description = "Linux VM 사설 IP 주소 목록"
  value       = var.create_linux_vm ? azurerm_network_interface.linux_vm[*].private_ip_address : []
}

# 하위 호환성을 위한 단일 값 출력
output "windows_vm_id" {
  description = "첫 번째 Windows VM ID (하위 호환성)"
  value       = var.create_windows_vm && length(azurerm_windows_virtual_machine.main) > 0 ? azurerm_windows_virtual_machine.main[0].id : null
}

output "linux_vm_id" {
  description = "첫 번째 Linux VM ID (하위 호환성)"
  value       = var.create_linux_vm && length(azurerm_linux_virtual_machine.main) > 0 ? azurerm_linux_virtual_machine.main[0].id : null
}

output "windows_public_ip" {
  description = "첫 번째 Windows VM 공용 IP 주소 (하위 호환성)"
  value       = var.create_windows_vm && var.create_public_ip && length(azurerm_public_ip.windows_vm) > 0 ? azurerm_public_ip.windows_vm[0].ip_address : null
}

output "linux_public_ip" {
  description = "첫 번째 Linux VM 공용 IP 주소 (하위 호환성)"
  value       = var.create_linux_vm && var.create_public_ip && length(azurerm_public_ip.linux_vm) > 0 ? azurerm_public_ip.linux_vm[0].ip_address : null
}

output "windows_private_ip" {
  description = "첫 번째 Windows VM 사설 IP 주소 (하위 호환성)"
  value       = var.create_windows_vm && length(azurerm_network_interface.windows_vm) > 0 ? azurerm_network_interface.windows_vm[0].private_ip_address : null
}

output "linux_private_ip" {
  description = "첫 번째 Linux VM 사설 IP 주소 (하위 호환성)"
  value       = var.create_linux_vm && length(azurerm_network_interface.linux_vm) > 0 ? azurerm_network_interface.linux_vm[0].private_ip_address : null
}

# 공통 정보
output "admin_username" {
  description = "VM 관리자 사용자 이름"
  value       = var.admin_username
}

output "admin_password" {
  description = "VM 관리자 비밀번호"
  value       = var.admin_password != null ? var.admin_password : (length(random_password.vm_password) > 0 ? random_password.vm_password[0].result : null)
  sensitive   = true
}

# 연결 명령어
output "windows_rdp_connections" {
  description = "Windows VM RDP 연결 명령어 목록"
  value = var.create_windows_vm && var.create_public_ip ? [
    for ip in azurerm_public_ip.windows_vm[*].ip_address : "mstsc /v:${ip}"
  ] : []
}

output "linux_ssh_connections" {
  description = "Linux VM SSH 연결 명령어 목록"
  value = var.create_linux_vm && var.create_public_ip ? [
    for ip in azurerm_public_ip.linux_vm[*].ip_address : "ssh ${var.admin_username}@${ip}"
  ] : []
}

# 하위 호환성을 위한 단일 연결 명령어
output "windows_rdp_connection" {
  description = "첫 번째 Windows VM RDP 연결 명령어 (하위 호환성)"
  value       = var.create_windows_vm && var.create_public_ip && length(azurerm_public_ip.windows_vm) > 0 ? "mstsc /v:${azurerm_public_ip.windows_vm[0].ip_address}" : null
}

output "linux_ssh_connection" {
  description = "첫 번째 Linux VM SSH 연결 명령어 (하위 호환성)"
  value       = var.create_linux_vm && var.create_public_ip && length(azurerm_public_ip.linux_vm) > 0 ? "ssh ${var.admin_username}@${azurerm_public_ip.linux_vm[0].ip_address}" : null
}

# 데이터 디스크 정보
output "windows_data_disk_ids" {
  description = "Windows VM 데이터 디스크 ID 목록"
  value       = var.create_windows_vm && var.create_data_disk ? azurerm_managed_disk.windows_data_disk[*].id : []
}

output "linux_data_disk_ids" {
  description = "Linux VM 데이터 디스크 ID 목록"
  value       = var.create_linux_vm && var.create_data_disk ? azurerm_managed_disk.linux_data_disk[*].id : []
}

output "data_disk_configuration" {
  description = "데이터 디스크 설정 정보"
  value = {
    created               = var.create_data_disk
    size_gb              = var.data_disk_size_gb
    storage_account_type = var.data_disk_storage_account_type
    caching              = var.data_disk_caching
    lun                  = var.data_disk_lun
  }
}

# 관리 ID 정보
output "windows_vm_principal_ids" {
  description = "Windows VM 관리 ID Principal ID 목록"
  value       = var.create_windows_vm && var.enable_managed_identity ? azurerm_windows_virtual_machine.main[*].identity[0].principal_id : []
}

output "linux_vm_principal_ids" {
  description = "Linux VM 관리 ID Principal ID 목록"
  value       = var.create_linux_vm && var.enable_managed_identity ? azurerm_linux_virtual_machine.main[*].identity[0].principal_id : []
}

output "windows_vm_tenant_ids" {
  description = "Windows VM 관리 ID Tenant ID 목록"
  value       = var.create_windows_vm && var.enable_managed_identity ? azurerm_windows_virtual_machine.main[*].identity[0].tenant_id : []
}

output "linux_vm_tenant_ids" {
  description = "Linux VM 관리 ID Tenant ID 목록"
  value       = var.create_linux_vm && var.enable_managed_identity ? azurerm_linux_virtual_machine.main[*].identity[0].tenant_id : []
}

output "managed_identity_configuration" {
  description = "관리 ID 설정 정보"
  value = {
    enabled               = var.enable_managed_identity
    type                 = var.managed_identity_type
    user_assigned_ids    = var.user_assigned_identity_ids
    role_assignments     = var.role_assignments
  }
}