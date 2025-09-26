# 완전 변수화된 프로젝트 출력 변수

# ========================================
# 기본 정보 출력
# ========================================
output "environment" {
  description = "배포 환경"
  value       = var.environment
}

output "project_name" {
  description = "프로젝트 이름"
  value       = var.project_name
}

output "location" {
  description = "Azure 지역"
  value       = var.location
}

# ========================================
# 리소스 그룹 출력
# ========================================
output "resource_group_name" {
  description = "사용된 리소스 그룹 이름"
  value       = local.resource_group_name
}

output "resource_group_location" {
  description = "사용된 리소스 그룹 위치"
  value       = local.resource_group_location
}

# ========================================


# ========================================
# Windows VM 출력
# ========================================
output "windows_vm_created" {
  description = "Windows VM 생성 여부"
  value       = var.create_windows_vm
}

output "windows_vm_count" {
  description = "생성된 Windows VM 개수"
  value       = var.create_windows_vm ? var.windows_vm_count : 0
}

output "windows_vm_names" {
  description = "Windows VM 이름 목록"
  value       = module.windows_vm.windows_vm_names
}

output "windows_vm_ids" {
  description = "Windows VM ID 목록"
  value       = module.windows_vm.windows_vm_ids
}

output "windows_public_ips" {
  description = "Windows VM 공용 IP 주소 목록"
  value       = module.windows_vm.windows_public_ips
}

output "windows_private_ips" {
  description = "Windows VM 사설 IP 주소 목록"
  value       = module.windows_vm.windows_private_ips
}

output "windows_rdp_connections" {
  description = "Windows VM RDP 연결 명령어 목록"
  value       = module.windows_vm.windows_rdp_connections
}

# ========================================
# Linux VM 출력
# ========================================
output "linux_vm_created" {
  description = "Linux VM 생성 여부"
  value       = var.create_linux_vm
}

output "linux_vm_count" {
  description = "생성된 Linux VM 개수"
  value       = var.create_linux_vm ? var.linux_vm_count : 0
}

output "linux_vm_names" {
  description = "Linux VM 이름 목록"
  value       = module.linux_vm.linux_vm_names
}

output "linux_vm_ids" {
  description = "Linux VM ID 목록"
  value       = module.linux_vm.linux_vm_ids
}

output "linux_public_ips" {
  description = "Linux VM 공용 IP 주소 목록"
  value       = module.linux_vm.linux_public_ips
}

output "linux_private_ips" {
  description = "Linux VM 사설 IP 주소 목록"
  value       = module.linux_vm.linux_private_ips
}

output "linux_ssh_connections" {
  description = "Linux VM SSH 연결 명령어 목록"
  value       = module.linux_vm.linux_ssh_connections
}

# ========================================
# 하위 호환성을 위한 단일 값 출력
# ========================================
output "windows_vm_public_ip" {
  description = "첫 번째 Windows VM 공용 IP 주소 (하위 호환성)"
  value       = module.windows_vm.windows_vm_public_ip
}

output "linux_vm_public_ip" {
  description = "첫 번째 Linux VM 공용 IP 주소 (하위 호환성)"
  value       = module.linux_vm.linux_vm_public_ip
}

output "windows_vm_private_ip" {
  description = "첫 번째 Windows VM 사설 IP 주소 (하위 호환성)"
  value       = module.windows_vm.windows_vm_private_ip
}

output "linux_vm_private_ip" {
  description = "첫 번째 Linux VM 사설 IP 주소 (하위 호환성)"
  value       = module.linux_vm.linux_vm_private_ip
}

output "windows_rdp_connection" {
  description = "첫 번째 Windows VM RDP 연결 명령어 (하위 호환성)"
  value       = module.windows_vm.windows_rdp_connection
}

output "linux_ssh_connection" {
  description = "첫 번째 Linux VM SSH 연결 명령어 (하위 호환성)"
  value       = module.linux_vm.linux_ssh_connection
}

# ========================================
# 공통 정보 출력
# ========================================
output "admin_username" {
  description = "VM 관리자 사용자 이름"
  value       = var.admin_username
}

output "admin_password" {
  description = "VM 관리자 비밀번호"
  value       = var.admin_password
  sensitive   = true
}

# ========================================
# 설정 정보 출력
# ========================================
output "use_existing_resources" {
  description = "기존 리소스 사용 설정"
  value = {
    resource_group = var.use_existing_resource_group
  }
}

output "image_configuration" {
  description = "이미지 설정 정보"
  value = {
    windows_image_sku = var.windows_vm_image_sku
    linux_image_sku   = var.linux_vm_image_sku
  }
}

output "vm_configuration" {
  description = "VM 설정 정보"
  value = {
    windows_vm_size = var.windows_vm_size
    linux_vm_size   = var.linux_vm_size
    windows_storage = var.windows_storage_account_type
    linux_storage   = var.linux_storage_account_type
    os_disk_size_gb = var.os_disk_size_gb
    public_ip_created = var.create_public_ip
  }
}

# ========================================
# 데이터 디스크 출력 - 사용하지 않음
# ========================================

# ========================================
# 관리 ID 출력
# ========================================
output "windows_vm_principal_ids" {
  description = "Windows VM 관리 ID Principal ID 목록"
  value       = module.windows_vm.windows_vm_principal_ids
}

output "linux_vm_principal_ids" {
  description = "Linux VM 관리 ID Principal ID 목록"
  value       = module.linux_vm.linux_vm_principal_ids
}

output "managed_identity_configuration" {
  description = "관리 ID 설정 정보"
  value = {
    enabled = var.enable_managed_identity
    type = var.managed_identity_type
    user_assigned_ids = var.user_assigned_identity_ids
    role_assignments = var.role_assignments
  }
}

# Windows VM 설정 안내
output "windows_setup_instructions" {
  description = "Windows VM 수동 설정 안내"
  value       = var.create_windows_vm && var.install_azure_cli ? module.windows_vm.windows_setup_instructions : []
}

# ========================================
# VM 공용 IP 주소 (접속용)
# ========================================
output "vm_public_ips" {
  description = "모든 VM의 공용 IP 주소"
  value = {
    linux_vm_ip  = var.create_linux_vm && var.create_public_ip ? module.linux_vm.linux_vm_public_ip : null
    windows_vm_ip = var.create_windows_vm && var.create_public_ip ? module.windows_vm.windows_vm_public_ip : null
  }
}

output "vm_connection_info" {
  description = "VM 접속 정보"
  value = {
    linux_ssh   = var.create_linux_vm && var.create_public_ip ? module.linux_vm.linux_ssh_connection : null
    windows_rdp = var.create_windows_vm && var.create_public_ip ? module.windows_vm.windows_rdp_connection : null
  }
}

# ========================================
# 네트워크 모듈 출력
# ========================================
output "network_public_ips" {
  description = "네트워크 모듈에서 생성된 공용 IP 정보"
  value = {
    ids      = module.network.public_ip_ids
    addresses = module.network.public_ip_addresses
    names    = module.network.public_ip_names
    fqdns    = module.network.public_ip_fqdns
  }
}

output "network_subnets" {
  description = "네트워크 모듈에서 관리하는 서브넷 정보"
  value = {
    ids                = module.network.subnet_ids
    names              = module.network.subnet_names
    address_prefixes   = module.network.subnet_address_prefixes
  }
}

output "network_nsgs" {
  description = "네트워크 모듈에서 관리하는 NSG 정보"
  value = {
    ids   = module.network.nsg_ids
    names = module.network.nsg_names
  }
}

output "network_configuration" {
  description = "네트워크 설정 정보"
  value       = module.network.network_configuration
}

# ========================================
# 진단 설정 출력
# ========================================
output "diagnostic_enabled" {
  description = "진단 설정 활성화 여부"
  value       = var.enable_diagnostic_settings
}

output "log_analytics_workspace_info" {
  description = "Log Analytics Workspace 정보"
  value = var.enable_diagnostic_settings ? {
    id    = module.diagnostic[0].log_analytics_workspace_id
    name  = module.diagnostic[0].log_analytics_workspace_name
  } : null
}

output "diagnostic_storage_account_info" {
  description = "진단용 Storage Account 정보"
  value = var.enable_diagnostic_settings && var.create_diagnostic_storage_account ? {
    id    = module.diagnostic[0].storage_account_id
    name  = module.diagnostic[0].storage_account_name
  } : null
}

output "diagnostic_action_group_info" {
  description = "진단용 Action Group 정보"
  value = var.enable_diagnostic_settings && var.create_diagnostic_action_group ? {
    id    = module.diagnostic[0].action_group_id
    name  = module.diagnostic[0].action_group_name
  } : null
}

output "diagnostic_settings_info" {
  description = "진단 설정 정보"
  value = var.enable_diagnostic_settings ? {
    settings_count = length(module.diagnostic[0].diagnostic_setting_ids)
    settings_names = module.diagnostic[0].diagnostic_setting_names
    configuration  = module.diagnostic[0].diagnostic_configuration
  } : null
}
