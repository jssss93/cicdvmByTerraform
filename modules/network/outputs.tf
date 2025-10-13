# Azure Network 모듈 출력

# ========================================
# 공용 IP 출력 (서브모듈에서 가져오기)
# ========================================
output "public_ip_ids" {
  description = "생성된 공용 IP ID 목록"
  value       = module.public_ip.public_ip_ids
}

output "public_ip_addresses" {
  description = "생성된 공용 IP 주소 목록"
  value       = module.public_ip.public_ip_addresses
}

output "public_ip_names" {
  description = "생성된 공용 IP 이름 목록"
  value       = module.public_ip.public_ip_names
}

output "public_ip_fqdns" {
  description = "생성된 공용 IP FQDN 목록"
  value       = module.public_ip.public_ip_fqdns
}

# Linux VM용 공용 IP 출력
output "linux_public_ip_id" {
  description = "Linux VM용 공용 IP ID"
  value       = module.public_ip.linux_public_ip_id
}

output "linux_public_ip_address" {
  description = "Linux VM용 공용 IP 주소"
  value       = module.public_ip.linux_public_ip_address
}

output "linux_public_ip_name" {
  description = "Linux VM용 공용 IP 이름"
  value       = module.public_ip.linux_public_ip_name
}

output "linux_public_ip_fqdn" {
  description = "Linux VM용 공용 IP FQDN"
  value       = module.public_ip.linux_public_ip_fqdn
}

# Windows VM용 공용 IP 출력
output "windows_public_ip_id" {
  description = "Windows VM용 공용 IP ID"
  value       = module.public_ip.windows_public_ip_id
}

output "windows_public_ip_address" {
  description = "Windows VM용 공용 IP 주소"
  value       = module.public_ip.windows_public_ip_address
}

output "windows_public_ip_name" {
  description = "Windows VM용 공용 IP 이름"
  value       = module.public_ip.windows_public_ip_name
}

output "windows_public_ip_fqdn" {
  description = "Windows VM용 공용 IP FQDN"
  value       = module.public_ip.windows_public_ip_fqdn
}

# 단일 공용 IP 출력 (하위 호환성)
output "public_ip_id" {
  description = "첫 번째 공용 IP ID (하위 호환성)"
  value       = length(module.public_ip.public_ip_ids) > 0 ? module.public_ip.public_ip_ids[0] : null
}

output "public_ip_address" {
  description = "첫 번째 공용 IP 주소 (하위 호환성)"
  value       = length(module.public_ip.public_ip_addresses) > 0 ? module.public_ip.public_ip_addresses[0] : null
}

output "public_ip_name" {
  description = "첫 번째 공용 IP 이름 (하위 호환성)"
  value       = length(module.public_ip.public_ip_names) > 0 ? module.public_ip.public_ip_names[0] : null
}

output "public_ip_fqdn" {
  description = "첫 번째 공용 IP FQDN (하위 호환성)"
  value       = length(module.public_ip.public_ip_fqdns) > 0 ? module.public_ip.public_ip_fqdns[0] : null
}

# ========================================
# 서브넷 출력
# ========================================
output "subnet_ids" {
  description = "사용 중인 서브넷 ID 목록"
  value = var.use_existing_subnet ? [data.azurerm_subnet.existing[0].id] : azurerm_subnet.main[*].id
}

output "subnet_names" {
  description = "사용 중인 서브넷 이름 목록"
  value = var.use_existing_subnet ? [data.azurerm_subnet.existing[0].name] : azurerm_subnet.main[*].name
}

output "subnet_address_prefixes" {
  description = "사용 중인 서브넷 주소 범위 목록"
  value = var.use_existing_subnet ? [data.azurerm_subnet.existing[0].address_prefixes[0]] : azurerm_subnet.main[*].address_prefixes[0]
}

# 단일 서브넷 출력 (하위 호환성)
output "subnet_id" {
  description = "사용 중인 서브넷 ID (하위 호환성)"
  value = var.use_existing_subnet ? data.azurerm_subnet.existing[0].id : (
    length(azurerm_subnet.main) > 0 ? azurerm_subnet.main[0].id : null
  )
}

output "subnet_name" {
  description = "사용 중인 서브넷 이름 (하위 호환성)"
  value = var.use_existing_subnet ? data.azurerm_subnet.existing[0].name : (
    length(azurerm_subnet.main) > 0 ? azurerm_subnet.main[0].name : null
  )
}

output "subnet_address_prefix" {
  description = "사용 중인 서브넷 주소 범위 (하위 호환성)"
  value = var.use_existing_subnet ? data.azurerm_subnet.existing[0].address_prefixes[0] : (
    length(azurerm_subnet.main) > 0 ? azurerm_subnet.main[0].address_prefixes[0] : null
  )
}

# ========================================
# NSG 출력 (기존 NSG 사용)
# ========================================
output "nsg_ids" {
  description = "사용 중인 NSG ID 목록"
  value = [data.azurerm_network_security_group.existing.id]
}

output "nsg_names" {
  description = "사용 중인 NSG 이름 목록"
  value = [data.azurerm_network_security_group.existing.name]
}

# 단일 NSG 출력 (하위 호환성)
output "nsg_id" {
  description = "사용 중인 NSG ID (하위 호환성)"
  value = data.azurerm_network_security_group.existing.id
}

output "nsg_name" {
  description = "사용 중인 NSG 이름 (하위 호환성)"
  value = data.azurerm_network_security_group.existing.name
}

# ========================================
# 네트워크 정보 출력
# ========================================
output "virtual_network_name" {
  description = "Virtual Network 이름"
  value       = var.existing_vnet_name
}

output "resource_group_name" {
  description = "리소스 그룹 이름"
  value       = var.resource_group_name
}

output "network_configuration" {
  description = "네트워크 설정 정보"
  value = {
    vnet_name              = var.existing_vnet_name
    use_existing_subnet    = var.use_existing_subnet
    existing_subnet_name   = var.existing_subnet_name
    create_new_subnet      = var.create_new_subnet
    existing_nsg_name      = var.existing_nsg_name
    create_public_ip       = var.create_public_ip
    public_ip_count        = length(module.public_ip.public_ip_ids)
  }
}
