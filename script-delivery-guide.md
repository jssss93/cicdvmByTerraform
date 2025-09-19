# VM 스크립트 전달 및 실행 가이드

이 가이드는 Terraform을 사용하여 Azure VM에 스크립트를 전달하고 VM 생성과 동시에 자동으로 실행하는 방법을 설명합니다.

## 🚀 개선된 기능

### 1. 스크립트 파일 전달
- **Linux VM**: Cloud-init을 통해 스크립트 파일들을 VM에 생성
- **Windows VM**: PowerShell을 통해 스크립트 파일들을 VM에 생성
- 여러 개의 스크립트 파일을 동시에 전달 가능
- 스크립트 실행 순서 제어 가능

### 2. 향상된 로깅 및 오류 처리
- 모든 스크립트 실행 과정이 로그에 기록됨
- 스크립트별 실행 결과 추적
- 오류 발생 시 상세한 오류 메시지 제공

## 📝 사용 방법

### terraform.tfvars 파일 설정 예시

```hcl
# Windows VM에 스크립트 전달 예시
script_files_windows = {
  "C:\\scripts\\setup-web-server.ps1" = <<-EOT
    # Web Server 설치 스크립트
    Write-Host "Web Server 설치 시작"
    
    # IIS 설치
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole -All
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServer -All
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-CommonHttpFeatures -All
    
    Write-Host "Web Server 설치 완료"
  EOT
  
  "C:\\scripts\\configure-firewall.ps1" = <<-EOT
    # 방화벽 설정 스크립트
    Write-Host "방화벽 규칙 설정 시작"
    
    # HTTP 포트 열기
    New-NetFirewallRule -DisplayName "HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow
    New-NetFirewallRule -DisplayName "HTTPS" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow
    
    Write-Host "방화벽 설정 완료"
  EOT
}

# 스크립트 실행 순서 지정 (Windows)
script_execution_order = {
  windows = [
    "C:\\scripts\\setup-web-server.ps1",
    "C:\\scripts\\configure-firewall.ps1"
  ]
  linux = []
}

# 기존 방식도 계속 지원 (하위 호환성)
custom_script_windows = "Write-Host '추가 설정 스크립트 실행'"
```

```hcl
# Linux VM에 스크립트 전달 예시
script_files_linux = {
  "/tmp/setup-nginx.sh" = <<-EOT
    #!/bin/bash
    # Nginx 설치 스크립트
    echo "Nginx 설치 시작"
    
    apt-get update
    apt-get install -y nginx
    
    systemctl enable nginx
    systemctl start nginx
    
    echo "Nginx 설치 완료"
  EOT
  
  "/tmp/configure-ssl.sh" = <<-EOT
    #!/bin/bash
    # SSL 설정 스크립트
    echo "SSL 설정 시작"
    
    # Let's Encrypt 인증서 설치
    apt-get install -y certbot python3-certbot-nginx
    
    echo "SSL 설정 완료"
  EOT
}

# 스크립트 실행 순서 지정 (Linux)
script_execution_order = {
  windows = []
  linux = [
    "/tmp/setup-nginx.sh",
    "/tmp/configure-ssl.sh"
  ]
}

# 기존 방식도 계속 지원 (하위 호환성)
custom_script_linux = "echo '추가 설정 스크립트 실행'"
```

## 🔧 실제 사용 예시

### 1. 웹 서버 자동 설정

```hcl
# Windows VM에 웹 서버 설정
script_files_windows = {
  "C:\\scripts\\install-iis.ps1" = <<-EOT
    Write-Host "IIS 설치 시작"
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole -All
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServer -All
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-CommonHttpFeatures -All
    Write-Host "IIS 설치 완료"
  EOT
  
  "C:\\scripts\\deploy-app.ps1" = <<-EOT
    Write-Host "애플리케이션 배포 시작"
    # 애플리케이션 배포 로직
    Write-Host "애플리케이션 배포 완료"
  EOT
}

script_execution_order = {
  windows = [
    "C:\\scripts\\install-iis.ps1",
    "C:\\scripts\\deploy-app.ps1"
  ]
  linux = []
}
```

### 2. 개발 환경 자동 설정

```hcl
# Linux VM에 개발 환경 설정
script_files_linux = {
  "/tmp/install-nodejs.sh" = <<-EOT
    #!/bin/bash
    echo "Node.js 설치 시작"
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    apt-get install -y nodejs
    echo "Node.js 설치 완료"
  EOT
  
  "/tmp/install-docker.sh" = <<-EOT
    #!/bin/bash
    echo "Docker 추가 설정 시작"
    usermod -aG docker azureuser
    echo "Docker 설정 완료"
  EOT
  
  "/tmp/clone-repo.sh" = <<-EOT
    #!/bin/bash
    echo "저장소 클론 시작"
    cd /home/azureuser
    git clone https://github.com/your-org/your-repo.git
    echo "저장소 클론 완료"
  EOT
}

script_execution_order = {
  windows = []
  linux = [
    "/tmp/install-nodejs.sh",
    "/tmp/install-docker.sh",
    "/tmp/clone-repo.sh"
  ]
}
```

## 📊 로그 확인 방법

### Linux VM
```bash
# Cloud-init 로그 확인
sudo cat /var/log/cloud-init-output.log

# VM 설정 로그 확인
sudo cat /var/log/vm-setup.log

# 설정 완료 확인
cat /tmp/vm-setup-complete.txt
```

### Windows VM
```powershell
# VM 설정 로그 확인
Get-Content C:\vm-setup.log

# 설정 완료 확인
Get-Content C:\vm-setup-complete.txt
```

## ⚠️ 주의사항

1. **스크립트 인코딩**: Windows 스크립트는 UTF-8 인코딩으로 저장됩니다.
2. **실행 권한**: Linux 스크립트는 자동으로 실행 권한(755)이 설정됩니다.
3. **실행 순서**: `script_execution_order`에 지정된 순서대로 스크립트가 실행됩니다.
4. **오류 처리**: 스크립트 실행 중 오류가 발생해도 다음 스크립트는 계속 실행됩니다.
5. **하위 호환성**: 기존 `custom_script_windows`와 `custom_script_linux` 변수도 계속 지원됩니다.

## 🔄 실행 흐름

### Linux VM
1. Cloud-init 시작
2. 기본 패키지 설치 (Azure CLI, Docker 등)
3. 사용자 정의 스크립트 파일들 생성
4. `script_execution_order.linux`에 지정된 순서로 스크립트 실행
5. 기존 `custom_script_linux` 실행 (있는 경우)
6. 시스템 정리 및 완료

### Windows VM
1. PowerShell 스크립트 시작
2. 기본 소프트웨어 설치 (Azure CLI, .NET SDK, Docker 등)
3. 사용자 정의 스크립트 파일들 생성
4. `script_execution_order.windows`에 지정된 순서로 스크립트 실행
5. 기존 `custom_script_windows` 실행 (있는 경우)
6. 재부팅 스케줄링

이제 VM 생성과 동시에 원하는 스크립트들을 자동으로 전달하고 실행할 수 있습니다! 🎉
