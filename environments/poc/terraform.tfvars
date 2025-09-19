# Windows Server 2022 Datacenter CI/CD 서버 스펙 설정 - poc
# 코드 컴파일과 Docker 이미지 빌드를 위한 고성능 구성

# ========================================
# 기본 설정
# ========================================
environment = "poc"
location = "Korea Central"

# 공통 태그
common_tags = {
  CostCenter  = "KT AXD"
  Environment = "poc"
  ManagedBy   = "Terraform"
  Owner       = "JongsuChoi"
  Project     = "hyundai-teams-meeting-ai-translator-cicd"
}

use_existing_resource_group = true
existing_resource_group_name = "rg-az01-poc-hyundai.teams-01"

# 기존 네트워킹 리소스 이름으로 설정
existing_vnet_name = "ict-poc-kttranslator-vnet-kc"
existing_subnet_name = "subnet-computing"
existing_nsg_name = "ict-poc-kttranslator-nsg-kc-compute"

# ========================================
# VM 설정 - Windows Server 2022 CI/CD 서버 스펙
# ========================================
vm_name_prefix = "ict-poc-kttranslator-cicivm01-kc"

# VM 개별 이름 설정 (각 VM의 정확한 이름 지정)
windows_vm_names = ["ict-poc-kttranslator-winvm01-kc"]
linux_vm_names = ["ict-poc-kttranslator-linuxvm01-kc"]

create_windows_vm = true  # 테스트용으로 비활성화
create_linux_vm = true
windows_vm_count = 1
linux_vm_count = 1

# VM 크기 및 스토리지 - 고성능 스펙
windows_vm_size = "Standard_D4s_v3"  # 4 vCPU, 16 GiB RAM
linux_vm_size = "Standard_D4s_v3"    # 4 vCPU, 16 GiB RAM (Linux도 동일 스펙)
windows_storage_account_type = "Premium_LRS"  # Premium SSD
linux_storage_account_type = "Premium_LRS"    # Premium SSD

# OS 디스크 크기 - 128 GiB
os_disk_size_gb = 128

# 데이터 디스크 설정 - 32 GiB Premium SSD
create_data_disk = true
data_disk_size_gb = 32
data_disk_storage_account_type = "Premium_LRS"
data_disk_caching = "ReadWrite"
data_disk_lun = 0

# 관리자 계정
admin_username = "cjs"
admin_password = "cjsvm1234!!!"  # 강력한 비밀번호 설정

# ========================================
# 네트워킹 설정 - 기존 인프라 활용
# ========================================
create_public_ip = true
public_ip_allocation_method = "Static"
public_ip_sku = "Standard"

# 기존 NSG 사용 (이름으로 지정 가능)
# existing_nsg_name = "your-existing-nsg-name"

# ========================================
# 이미지 설정 - Windows Server 2022 Datacenter
# ========================================

# Windows Server 2022 Datacenter 이미지 (원본 이미지 세부 정보 기준)
windows_vm_image_publisher = "MicrosoftWindowsServer"
windows_vm_image_offer = "WindowsServer"
windows_vm_image_sku = "2022-datacenter-azure-edition"
windows_vm_image_version = "latest"

# Ubuntu 24.04 LTS 이미지 (원본 이미지 세부 정보 기준)
linux_vm_image_publisher = "canonical"
linux_vm_image_offer = "ubuntu-24_04-lts"
linux_vm_image_sku = "server"
linux_vm_image_version = "latest"

# ========================================
# Azure CLI 및 도구 설치 설정
# ========================================
install_azure_cli = true  # VM 생성 시 Azure CLI, .NET SDK, Docker 자동 설치

# ========================================
# 사용자 정의 스크립트 설정 (테스트용)
# ========================================
# Custom Script Extension 테스트용 스크립트 (Base64 인코딩 방식)
# install-linux.sh 파일 내용을 Custom Script Extension으로 실행
custom_script_linux = <<-EOT
#!/bin/bash
# Linux VM 초기 설정 스크립트 (Bash)
# Azure CLI, Docker 및 개발 도구 설치
# VM 생성 시 자동 실행되는 스크립트

# 로그 파일 설정
LOG_FILE="/var/log/vm-setup.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# 로그 함수
log() {
    echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE"
}

log "Linux VM 초기 설정 시작"

# 시스템 업데이트
log "시스템 패키지 업데이트 중..."
apt-get update -y

# 필수 패키지 설치
log "필수 패키지 설치 중..."
apt-get install -y curl apt-transport-https lsb-release gnupg

# Microsoft GPG 키 추가
log "Microsoft GPG 키 추가 중..."
curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null

# Azure CLI 리포지토리 추가
log "Azure CLI 리포지토리 추가 중..."
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | tee /etc/apt/sources.list.d/azure-cli.list

# 패키지 목록 업데이트
log "패키지 목록 업데이트 중..."
apt-get update -y

# Azure CLI 설치
log "Azure CLI 설치 중..."
apt-get install -y azure-cli

# Azure CLI 버전 확인
log "Azure CLI 설치 확인 중..."
if command -v az &> /dev/null; then
    AZ_VERSION=$(az version --output tsv 2>/dev/null | head -n1)
    log "Azure CLI 설치 성공: $AZ_VERSION"
else
    log "Azure CLI 설치 실패"
fi

# 추가 도구 설치
log "추가 도구 설치 중..."
apt-get install -y git wget curl unzip jq

# Docker 설치 (선택적)
log "Docker 설치 중..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker $USER

# 시스템 서비스 활성화
log "시스템 서비스 설정 중..."
systemctl enable docker
systemctl start docker

# 정리 작업
log "정리 작업 중..."
apt-get autoremove -y
apt-get autoclean

log "모든 설치 작업 완료"

# 설치 완료 마커 파일 생성
touch /tmp/vm-setup-complete

log "VM 초기 설정 스크립트 종료"
EOT

custom_script_windows = <<-EOT
Write-Host "Windows VM 설정 시작"
"$(Get-Date): Windows VM 설정 시작" | Out-File -FilePath "C:\vm-setup.log" -Force
Write-Host "Azure CLI 설치 중..."
Set-ExecutionPolicy Bypass -Scope Process -Force
try {
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    choco install azure-cli -y --force
    "$(Get-Date): Azure CLI 설치 완료" | Out-File -FilePath "C:\setup-complete.txt" -Force
    Write-Host "설정 완료"
} catch {
    "$(Get-Date): 오류 발생" | Out-File -FilePath "C:\setup-error.txt" -Force
    Write-Host "설정 중 오류 발생"
}
# Windows VM 초기 설정 및 Azure CLI 설치 스크립트
Write-Host "=== Windows VM 초기 설정 시작 ===" -ForegroundColor Green

# 로그 파일 설정
$logFile = "C:\vm-setup.log"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# 로그 함수
function Write-Log {
    param($Message)
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage
    try {
        Add-Content -Path $logFile -Value $logMessage -Force
    } catch {
        Write-Host "로그 파일 쓰기 실패: $($_.Exception.Message)"
    }
}

try {
    Write-Log "Windows VM 초기 설정 시작"
    Write-Log "실행 시간: $(Get-Date)"
    Write-Log "현재 사용자: $env:USERNAME"

    # PowerShell 실행 정책 설정
    Write-Log "PowerShell 실행 정책 설정 중..."
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force

    # Chocolatey 설치 (패키지 관리자)
    Write-Log "Chocolatey 설치 중..."
    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
        # PATH 환경변수 새로고침
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")
        Write-Log "Chocolatey 설치 완료"
    } else {
        Write-Log "Chocolatey 이미 설치됨"
    }

    # Azure CLI 설치
    Write-Log "Azure CLI 설치 중..."
    choco install azure-cli -y --force
    
    # PATH 환경변수 새로고침
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")
    
    # Azure CLI 버전 확인
    Write-Log "Azure CLI 설치 확인 중..."
    Start-Sleep -Seconds 5
    $azVersion = & az version --output table 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Azure CLI 설치 성공"
    } else {
        Write-Log "Azure CLI 버전 확인 실패, 재시도..."
    }

    # Git 설치
    Write-Log "Git 설치 중..."
    choco install git -y --force

    # .NET SDK 설치
    Write-Log ".NET SDK 설치 중..."
    choco install dotnet-sdk -y --force

    # Docker Desktop 설치 (Windows Server에서는 Docker Engine)
    Write-Log "Docker 설치 중..."
    choco install docker-desktop -y --force

    # 설치 완료 파일 생성
    Write-Log "설치 완료 파일 생성 중..."
    $completionData = @"
Windows VM 초기 설정 완료
설치 시간: $(Get-Date)
설치된 소프트웨어:
- Azure CLI
- Git
- .NET SDK  
- Docker Desktop
- Chocolatey

로그 파일: C:\vm-setup.log
"@
    
    $completionData | Out-File -FilePath "C:\vm-setup-complete.txt" -Encoding UTF8 -Force
    Write-Log "설치 완료 파일 생성됨: C:\vm-setup-complete.txt"

    # 테스트 파일도 생성
    "Custom Script Extension 실행 완료: $(Get-Date)" | Out-File -FilePath "C:\custom-script-test-complete.txt" -Encoding UTF8 -Force
    Write-Log "테스트 파일 생성됨: C:\custom-script-test-complete.txt"

    Write-Log "=== Windows VM 초기 설정 완료 ==="
    
} catch {
    Write-Log "오류 발생: $($_.Exception.Message)"
    Write-Host "스크립트 실행 중 오류 발생: $($_.Exception.Message)" -ForegroundColor Red
    exit 0
}
EOT

# ========================================
# 관리 ID 설정
# ========================================
enable_managed_identity = true
managed_identity_type = "SystemAssigned"

# VM 관리 ID에 할당할 역할들
role_assignments = {
  "custom_teams_ai_role" = {
    role_definition_name = "Custom-Role-poc-Teams-AI"
    scope               = "/subscriptions/d69e62aa-ef39-4bc0-b745-57ebc2bddcc8/resourceGroups/rg-az01-poc-hyundai.teams-01"
  }
  "storage_access" = {
    role_definition_name = "Storage Blob Data Contributor"
    scope               = "/subscriptions/d69e62aa-ef39-4bc0-b745-57ebc2bddcc8/resourceGroups/rg-az01-poc-hyundai.teams-01"
  }
}

# ========================================
# 진단 설정 (Diagnostic Settings)
# ========================================
enable_diagnostic_settings = true  # VM 진단 설정 활성화

# 기존 Log Analytics Workspace 사용
log_analytics_workspace_name = "ict-poc-kttranslator-law-kc"
log_analytics_resource_group_name = "rg-az01-poc-hyundai.teams-01"

# ========================================
# 고급 설정
# ========================================
enable_boot_diagnostics = true
