# Linux VM 모듈 출력

# Linux VM 정보
output "linux_vm_ids" {
  description = "Linux VM ID 목록"
  value       = azurerm_linux_virtual_machine.main[*].id
}

output "linux_vm_names" {
  description = "Linux VM 이름 목록"
  value       = azurerm_linux_virtual_machine.main[*].name
}

output "linux_public_ips" {
  description = "Linux VM 공용 IP 주소 목록 (네트워크 모듈에서 관리)"
  value       = var.linux_public_ip_id != null ? [var.linux_public_ip_id] : []
}

output "linux_private_ips" {
  description = "Linux VM 사설 IP 주소 목록"
  value       = azurerm_network_interface.linux_vm[*].private_ip_address
}

# 하위 호환성을 위한 단일 값 출력
output "linux_vm_id" {
  description = "첫 번째 Linux VM ID (하위 호환성)"
  value       = length(azurerm_linux_virtual_machine.main) > 0 ? azurerm_linux_virtual_machine.main[0].id : null
}

output "linux_vm_name" {
  description = "첫 번째 Linux VM 이름 (하위 호환성)"
  value       = length(azurerm_linux_virtual_machine.main) > 0 ? azurerm_linux_virtual_machine.main[0].name : null
}

output "linux_vm_public_ip" {
  description = "첫 번째 Linux VM 공용 IP 주소 (하위 호환성)"
  value       = var.linux_public_ip_id
}

output "linux_vm_private_ip" {
  description = "첫 번째 Linux VM 사설 IP 주소 (하위 호환성)"
  value       = length(azurerm_network_interface.linux_vm) > 0 ? azurerm_network_interface.linux_vm[0].private_ip_address : null
}

# 연결 정보 (네트워크 모듈에서 관리)
output "linux_ssh_connections" {
  description = "Linux VM SSH 연결 명령어 목록"
  value = var.linux_public_ip_id != null ? [
    "ssh ${var.admin_username}@<public-ip-address>"
  ] : []
}

output "linux_ssh_connection" {
  description = "첫 번째 Linux VM SSH 연결 명령어 (하위 호환성)"
  value = var.linux_public_ip_id != null ? "ssh ${var.admin_username}@<public-ip-address>" : null
}

# 데이터 디스크 정보
# 데이터 디스크 출력 - 사용하지 않음

# 관리 ID 정보
output "linux_vm_principal_ids" {
  description = "Linux VM 관리 ID Principal ID 목록"
  value = var.enable_managed_identity ? [
    for vm in azurerm_linux_virtual_machine.main :
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
  value       = var.admin_password
  sensitive   = true
}
