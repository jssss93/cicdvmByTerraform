# Windows VM 모듈 출력

# Windows VM 정보
output "windows_vm_ids" {
  description = "Windows VM ID 목록"
  value       = azurerm_windows_virtual_machine.main[*].id
}

output "windows_vm_names" {
  description = "Windows VM 이름 목록"
  value       = azurerm_windows_virtual_machine.main[*].name
}

output "windows_public_ips" {
  description = "Windows VM 공용 IP 주소 목록"
  value       = var.create_public_ip ? azurerm_public_ip.windows_vm[*].ip_address : []
}

output "windows_private_ips" {
  description = "Windows VM 사설 IP 주소 목록"
  value       = azurerm_network_interface.windows_vm[*].private_ip_address
}

# 하위 호환성을 위한 단일 값 출력
output "windows_vm_id" {
  description = "첫 번째 Windows VM ID (하위 호환성)"
  value       = length(azurerm_windows_virtual_machine.main) > 0 ? azurerm_windows_virtual_machine.main[0].id : null
}

output "windows_vm_name" {
  description = "첫 번째 Windows VM 이름 (하위 호환성)"
  value       = length(azurerm_windows_virtual_machine.main) > 0 ? azurerm_windows_virtual_machine.main[0].name : null
}

output "windows_vm_public_ip" {
  description = "첫 번째 Windows VM 공용 IP 주소 (하위 호환성)"
  value       = var.create_public_ip && length(azurerm_public_ip.windows_vm) > 0 ? azurerm_public_ip.windows_vm[0].ip_address : null
}

output "windows_vm_private_ip" {
  description = "첫 번째 Windows VM 사설 IP 주소 (하위 호환성)"
  value       = length(azurerm_network_interface.windows_vm) > 0 ? azurerm_network_interface.windows_vm[0].private_ip_address : null
}

# 연결 정보
output "windows_rdp_connections" {
  description = "Windows VM RDP 연결 명령어 목록"
  value = var.create_public_ip ? [
    for ip in azurerm_public_ip.windows_vm[*].ip_address : 
    "mstsc /v:${ip}"
  ] : []
}

output "windows_rdp_connection" {
  description = "첫 번째 Windows VM RDP 연결 명령어 (하위 호환성)"
  value = var.create_public_ip && length(azurerm_public_ip.windows_vm) > 0 ? "mstsc /v:${azurerm_public_ip.windows_vm[0].ip_address}" : null
}

# 데이터 디스크 정보
output "windows_data_disk_ids" {
  description = "Windows VM 데이터 디스크 ID 목록"
  value       = var.create_data_disk ? azurerm_managed_disk.windows_data_disk[*].id : []
}

# 관리 ID 정보
output "windows_vm_principal_ids" {
  description = "Windows VM 관리 ID Principal ID 목록"
  value = var.enable_managed_identity ? [
    for vm in azurerm_windows_virtual_machine.main :
    vm.identity[0].principal_id
  ] : []
}

# 관리자 정보
output "admin_username" {
  description = "VM 관리자 사용자 이름"
  value       = var.admin_username
}

output "admin_password" {
  description = "VM 관리자 비밀번호"
  value       = var.admin_password != null ? var.admin_password : (length(random_password.vm_password) > 0 ? random_password.vm_password[0].result : null)
  sensitive   = true
}

# Windows VM 설정 안내
output "windows_setup_instructions" {
  description = "Windows VM 수동 설정 안내"
  value       = local.windows_setup_instructions
}
