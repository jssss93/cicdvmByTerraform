# Windows VM 초기 설정 스크립트 (PowerShell)
# Azure CLI, .NET 9 SDK 및 개발 도구 설치
# VM 생성 시 자동 실행되는 스크립트

# 로그 파일 설정
$logFile = "C:\vm-setup.log"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

function Write-Log {
    param($Message)
    $logMessage = "[$timestamp] $Message"
    Write-Output $logMessage
    Add-Content -Path $logFile -Value $logMessage
}

Write-Log "Windows VM 초기 설정 시작"

try {
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
    }
    
    # Azure CLI 설치
    Write-Log "Azure CLI 설치 중..."
    choco install azure-cli -y
    
    # PATH 환경변수 새로고침
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")
    
    # Azure CLI 버전 확인
    Write-Log "Azure CLI 설치 확인 중..."
    $azVersion = & az version --output tsv 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Azure CLI 설치 성공: $azVersion"
    } else {
        Write-Log "Azure CLI 버전 확인 실패"
    }
    
    # 추가 도구 설치
    Write-Log "추가 도구 설치 중..."
    choco install git -y
    choco install curl -y
    choco install wget -y
    
    # .NET 9 SDK 설치
    Write-Log ".NET 9 SDK 설치 중..."
    choco install dotnet-9.0-sdk -y
    
    # .NET 설치 확인
    Write-Log ".NET 설치 확인 중..."
    $dotnetVersion = & dotnet --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Log ".NET SDK 설치 성공: $dotnetVersion"
    } else {
        Write-Log ".NET SDK 버전 확인 실패, 직접 다운로드 시도..."
        
        # 직접 다운로드 방식
        $dotnetUrl = "https://download.microsoft.com/download/7/8/b/78b16d5c-acff-4d62-8b62-9e0e6df34cbe/dotnet-sdk-9.0.100-win-x64.exe"
        $dotnetInstaller = "$env:TEMP\dotnet-sdk-9.0.100-win-x64.exe"
        
        Write-Log "직접 .NET 9 SDK 다운로드 중..."
        Invoke-WebRequest -Uri $dotnetUrl -OutFile $dotnetInstaller
        
        Write-Log ".NET 9 SDK 설치 중..."
        Start-Process -FilePath $dotnetInstaller -ArgumentList "/quiet" -Wait
        
        # PATH 환경변수 새로고침
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")
        
        # 다시 버전 확인
        $dotnetVersion = & dotnet --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log ".NET SDK 직접 설치 성공: $dotnetVersion"
        } else {
            Write-Log ".NET SDK 설치 실패"
        }
    }
    
    # Docker Engine 설치 (Windows Server용)
    Write-Log "Docker Engine 설치 중..."
    choco install docker-engine -y
    
    # Windows 컨테이너 기능 활성화
    Write-Log "Windows 컨테이너 기능 활성화 중..."
    DISM /Online /Enable-Feature /All /FeatureName:Microsoft-Hyper-V /NoRestart
    DISM /Online /Enable-Feature /All /FeatureName:Containers /NoRestart
    
    # PATH 환경변수 새로고침
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")
    
    # Docker 서비스 시작
    Write-Log "Docker 서비스 시작 중..."
    Start-Service -Name "docker" -ErrorAction SilentlyContinue
    
    # Docker 설치 확인
    Write-Log "Docker 설치 확인 중..."
    Start-Sleep -Seconds 10  # Docker 서비스 시작 대기
    $dockerVersion = & docker --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Docker Engine 설치 성공: $dockerVersion"
    } else {
        Write-Log "Docker Engine 설치 실패"
        
        # Docker 서비스 상태 확인
        $dockerService = Get-Service -Name "docker" -ErrorAction SilentlyContinue
        if ($dockerService) {
            Write-Log "Docker 서비스 상태: $($dockerService.Status)"
        } else {
            Write-Log "Docker 서비스를 찾을 수 없습니다"
        }
    }
    
    Write-Log "Azure CLI, .NET SDK 및 Docker 설치 완료"
    
} catch {
    Write-Log "오류 발생: $($_.Exception.Message)"
    Write-Log "스택 트레이스: $($_.ScriptStackTrace)"
}

# 사용자 정의 스크립트 실행
$customScript = "${custom_script}"
if ($customScript -and $customScript.Trim() -ne "") {
    Write-Log "사용자 정의 스크립트 실행 중..."
    try {
        Invoke-Expression $customScript
        Write-Log "사용자 정의 스크립트 실행 완료"
    } catch {
        Write-Log "사용자 정의 스크립트 실행 오류: $($_.Exception.Message)"
    }
}

Write-Log "모든 설치 작업 완료 - Hyper-V 및 컨테이너 기능 활성화를 위해 재부팅 시작"

# 재부팅 스케줄링 (1분 후)
Write-Log "1분 후 자동 재부팅됩니다..."
shutdown /r /t 60 /c "VM 초기 설정 완료 - Hyper-V 및 Docker 활성화를 위한 재부팅"

# 설치 완료 마커 파일 생성
New-Item -Path "C:\vm-setup-complete.txt" -ItemType File -Force
Add-Content -Path "C:\vm-setup-complete.txt" -Value "VM 초기 설정 완료: $(Get-Date)"
Add-Content -Path "C:\vm-setup-complete.txt" -Value "설치된 소프트웨어: Azure CLI, .NET 9 SDK, Docker Engine, Git"
Add-Content -Path "C:\vm-setup-complete.txt" -Value "활성화된 기능: Hyper-V, Windows 컨테이너"

Write-Log "VM 초기 설정 스크립트 완료"
