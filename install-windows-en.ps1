 # PowerShell 인코딩 설정
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

# 로그 함수
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage
    Add-Content -Path "C:\vm-setup.log" -Value $logMessage -Force -Encoding UTF8
}

Write-Log "==== Stage 1: Base installation started ===="

# 임시 폴더 권한 설정
Write-Log "임시 폴더 권한 설정 중..."
try {
    $tempPaths = @(
        "C:\Windows\system32\config\systemprofile\AppData\Local\Temp",
        "C:\Windows\system32\config\systemprofile\AppData\Local",
        "C:\Windows\system32\config\systemprofile\AppData",
        "C:\Windows\Temp",
        "$env:TEMP",
        "C:\temp"
    )
    
    foreach ($tempPath in $tempPaths) {
        if (!(Test-Path $tempPath)) {
            New-Item -Path $tempPath -ItemType Directory -Force
            Write-Log "임시 폴더 생성: $tempPath"
        }
        
        # 더 강력한 권한 설정
        try {
            # 기본 권한 설정
            icacls $tempPath /grant "NT AUTHORITY\SYSTEM:(OI)(CI)F" /T /Q
            icacls $tempPath /grant "Administrators:(OI)(CI)F" /T /Q
            icacls $tempPath /grant "Users:(OI)(CI)RX" /T /Q
            
            # 추가 권한 설정 (DISM용)
            icacls $tempPath /grant "Everyone:(OI)(CI)F" /T /Q
            icacls $tempPath /grant "BUILTIN\Users:(OI)(CI)F" /T /Q
            
            Write-Log "권한 설정 완료: $tempPath"
        } catch {
            Write-Log "권한 설정 실패: $tempPath - $($_.Exception.Message)"
        }
    }
    
    # DISM 전용 임시 폴더 환경변수 설정
    $env:TEMP = "C:\Windows\Temp"
    $env:TMP = "C:\Windows\Temp"
    [Environment]::SetEnvironmentVariable("TEMP", "C:\Windows\Temp", "Machine")
    [Environment]::SetEnvironmentVariable("TMP", "C:\Windows\Temp", "Machine")
    Write-Log "DISM 임시 폴더 환경변수 설정 완료"
    
} catch {
    Write-Log "임시 폴더 권한 설정 오류: $($_.Exception.Message)"
}

# Chocolatey 설치
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Log "Installing Chocolatey..."
    $env:chocolateyUseWindowsCompression = 'true'
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Write-Log "Chocolatey installation completed"
} else {
    Write-Log "Chocolatey already installed"
}

$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")

# .NET 9 SDK (최신 안정 버전)
Write-Log "Installing .NET 9 SDK..."
choco install dotnet-9.0-sdk --version=9.0.305 -y
Write-Log ".NET 9 SDK installation attempted"

# Azure CLI (최신 안정 버전)
Write-Log "Installing Azure CLI..."
choco install azure-cli --version=2.59.0 -y
Write-Log "Azure CLI installation attempted"

# Docker Engine (Chocolatey로 설치)
Write-Log "Installing Docker Engine..."
choco install docker-engine --version=20.10.24 -y
Write-Log "Docker Engine installation attempted"

# GitHub Actions Runner (Stage1로 이동)
Write-Log "Installing GitHub Actions Runner..."
try {
    # Create a folder under the drive root
    $runnerPath = "C:\actions-runner"
    if (!(Test-Path $runnerPath)) {
        New-Item -Path $runnerPath -ItemType Directory -Force
        Write-Log "Created GitHub Actions Runner directory: $runnerPath"
    }

    Set-Location $runnerPath

    # Download the latest runner package
    $runnerVersion = "v2.328.0"
    $zipFileName = "actions-runner-win-x64-2.328.0.zip"
    $downloadUrl = "https://github.com/actions/runner/releases/download/$runnerVersion/$zipFileName"

    Write-Log "Downloading GitHub Actions Runner from $downloadUrl..."
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFileName -UseBasicParsing
    Write-Log "Download completed: $zipFileName"

    # Extract the installer
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory("$PWD\$zipFileName", "$PWD")
    Write-Log "GitHub Actions Runner extracted to $PWD"

    # Clean up zip file
    Remove-Item $zipFileName -Force
    Write-Log "GitHub Actions Runner installation completed"

    # Create setup instructions file
    $setupInstructions = @"
GitHub Actions Runner Setup Instructions
========================================

1. Configure the runner:
   cd C:\actions-runner
   .\config.cmd --url https://github.com/your-org/your-repo --token YOUR_TOKEN

2. Start the service:
   .\svc.cmd start

3. Check service status:
   .\svc.cmd status

4. Stop the service:
   .\svc.cmd stop

5. Uninstall the service:
   .\svc.cmd uninstall

Note: The service is already installed and will auto-start on boot after configuration.
"@

    $setupInstructions | Out-File -FilePath "C:\actions-runner\SETUP_INSTRUCTIONS.txt" -Force
    Write-Log "SETUP_INSTRUCTIONS.txt created in C:\actions-runner"
} catch {
    Write-Log "Error installing GitHub Actions Runner: $($_.Exception.Message)"
}

# Windows 기능 활성화 (DISM 사용)
Write-Log "Enabling Windows Container and Hyper-V features using DISM..."
try {
    # DISM 실행 전 추가 환경변수 설정
    $env:TEMP = "C:\Windows\Temp"
    $env:TMP = "C:\Windows\Temp"
    $env:DISM_TEMP = "C:\Windows\Temp"
    
    # DISM 로그 폴더 설정
    $dismLogPath = "C:\Windows\Logs\DISM"
    if (!(Test-Path $dismLogPath)) {
        New-Item -Path $dismLogPath -ItemType Directory -Force
        icacls $dismLogPath /grant "Everyone:(OI)(CI)F" /T /Q
    }
    
    # Container 기능 활성화 (강제, 재부팅 질문 없음)
    Write-Log "Enabling Container feature using DISM with quiet mode..."
    $containerOutput = & dism.exe /online /enable-feature /featurename:containers /all /norestart /quiet /logpath:"$dismLogPath\container.log" 2>&1
    Write-Log "DISM Container output: $containerOutput"
    
    # Hyper-V 기능 활성화 (강제, 재부팅 질문 없음)
    Write-Log "Enabling Hyper-V feature using DISM with quiet mode..."
    $hyperVOutput = & dism.exe /online /enable-feature /featurename:Microsoft-Hyper-V /all /norestart /quiet /logpath:"$dismLogPath\hyperv.log" 2>&1
    Write-Log "DISM Hyper-V output: $hyperVOutput"
    
    # DISM 오류 발생 시 대안 방법 시도
    if ($containerOutput -match "Error: 3" -or $hyperVOutput -match "Error: 3") {
        Write-Log "DISM 오류 감지 - 대안 방법으로 Windows 기능 활성화 시도..."
        
        # PowerShell을 통한 Windows 기능 활성화
        try {
            Write-Log "PowerShell을 통한 Container 기능 활성화 시도..."
            Enable-WindowsOptionalFeature -Online -FeatureName containers -All -NoRestart -ErrorAction SilentlyContinue
            Write-Log "PowerShell Container 기능 활성화 완료"
        } catch {
            Write-Log "PowerShell Container 기능 활성화 실패: $($_.Exception.Message)"
        }
        
        try {
            Write-Log "PowerShell을 통한 Hyper-V 기능 활성화 시도..."
            Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart -ErrorAction SilentlyContinue
            Write-Log "PowerShell Hyper-V 기능 활성화 완료"
        } catch {
            Write-Log "PowerShell Hyper-V 기능 활성화 실패: $($_.Exception.Message)"
        }
    }
    
    # 기능 상태 확인
    Write-Log "Checking feature status..."
    $containerStatus = & dism.exe /online /get-featureinfo /featurename:containers 2>&1
    $hyperVStatus = & dism.exe /online /get-featureinfo /featurename:Microsoft-Hyper-V 2>&1
    Write-Log "Container feature status: $containerStatus"
    Write-Log "Hyper-V feature status: $hyperVStatus"
    
    Write-Log "Windows Features configuration completed using DISM with quiet mode"
} catch {
    Write-Log "Error enabling Windows features with DISM: $($_.Exception.Message)"
    Write-Log "DISM 오류가 발생했지만 재부팅 후 기능이 활성화될 수 있습니다."
}

# 2단계 스크립트 작성
$stage2Content = @'
# Stage 2: Post-reboot configuration
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage
    Add-Content -Path "C:\vm-setup.log" -Value $logMessage -Force
}

Write-Log "==== Stage 2: Post-reboot tasks ===="

# Windows 기능 상태 확인
Write-Log "Checking Windows features status after reboot..."
try {
    $containerStatus = & dism.exe /online /get-featureinfo /featurename:containers 2>&1
    $hyperVStatus = & dism.exe /online /get-featureinfo /featurename:Microsoft-Hyper-V 2>&1
    Write-Log "Container feature status: $containerStatus"
    Write-Log "Hyper-V feature status: $hyperVStatus"
} catch {
    Write-Log "Error checking Windows features status: $($_.Exception.Message)"
}

# Docker Engine 서비스 시작
Write-Log "Checking Docker Engine installation..."
try {
    # Docker 서비스 확인
    $dockerService = Get-Service -Name "docker" -ErrorAction SilentlyContinue
    
    if ($dockerService) {
        Write-Log "Docker service found: $($dockerService.Status)"
        
        # Docker Desktop 서비스도 확인
        $dockerDesktopService = Get-Service -Name "com.docker.service" -ErrorAction SilentlyContinue
        if ($dockerDesktopService) {
            Write-Log "Docker Desktop service found: $($dockerDesktopService.Status)"
            Write-Log "Starting Docker Desktop service..."
            Start-Service "com.docker.service" -ErrorAction SilentlyContinue
        }
        
        # Docker Engine 서비스 시작 시도
        if ($dockerService.Status -ne "Running") {
            Write-Log "Attempting to start Docker Engine service..."
            try {
                Start-Service docker -ErrorAction Stop
                Write-Log "Docker Engine service started successfully"
            } catch {
                Write-Log "Failed to start Docker Engine service: $($_.Exception.Message)"
                Write-Log "This is common on Windows Server - Docker may need manual configuration"
                
                # Docker Desktop 대안 확인
                if ($dockerDesktopService) {
                    Write-Log "Trying Docker Desktop as alternative..."
                    Start-Service "com.docker.service" -ErrorAction SilentlyContinue
                }
            }
        } else {
            Write-Log "Docker service is already running"
        }
        
        # Docker가 준비될 때까지 대기
        Write-Log "Waiting for Docker to be ready..."
        $dockerReady = $false
        $attempts = 0
        $maxAttempts = 30
        
        while (-not $dockerReady -and $attempts -lt $maxAttempts) {
            try {
                $dockerInfo = & docker info 2>&1
                if ($LASTEXITCODE -eq 0) {
                    $dockerReady = $true
                    Write-Log "Docker is ready and responding"
                } else {
                    Start-Sleep -Seconds 2
                    $attempts++
                    Write-Log "Waiting for Docker... (attempt $attempts/$maxAttempts)"
                }
            } catch {
                Start-Sleep -Seconds 2
                $attempts++
                Write-Log "Docker not ready yet... (attempt $attempts/$maxAttempts)"
            }
        }
        
        if (-not $dockerReady) {
            Write-Log "Docker did not become ready within timeout period"
            Write-Log "Docker may need manual configuration or Windows Container feature setup"
        }
    } else {
        Write-Log "Docker service not found - checking for Docker Desktop..."
        
        # Docker Desktop 서비스 확인
        $dockerDesktopService = Get-Service -Name "com.docker.service" -ErrorAction SilentlyContinue
        if ($dockerDesktopService) {
            Write-Log "Docker Desktop service found: $($dockerDesktopService.Status)"
            Write-Log "Starting Docker Desktop service..."
            Start-Service "com.docker.service" -ErrorAction SilentlyContinue
        } else {
            Write-Log "No Docker services found - Docker may not be properly installed"
            Write-Log "This is common on Windows Server - Docker Engine may need manual setup"
        }
    }
} catch {
    Write-Log "Error with Docker setup: $($_.Exception.Message)"
    Write-Log "Docker may need manual configuration on Windows Server"
}

# GitHub Actions Runner 서비스 설정 (이미 Stage1에서 설치됨)
Write-Log "Configuring GitHub Actions Runner as Windows Service..."
try {
    $runnerPath = "C:\actions-runner"
    if (Test-Path $runnerPath) {
        Set-Location $runnerPath
        
        # Install as Windows Service (this will auto-start on boot)
        & ".\svc.cmd" install --runAsService
        if ($LASTEXITCODE -eq 0) {
            Write-Log "GitHub Actions Runner service installed successfully"
        } else {
            Write-Log "Error installing GitHub Actions Runner service. Exit code: $LASTEXITCODE"
        }
    } else {
        Write-Log "GitHub Actions Runner directory not found - may not have been installed in Stage1"
    }
} catch {
    Write-Log "Error configuring GitHub Actions Runner service: $($_.Exception.Message)"
}

# Verify
Write-Log "Verifying installations..."
$dotnetVersion = & dotnet --version 2>&1
$azVersion = & az --version 2>&1 | Select-Object -First 1
$dockerVersion = & docker --version 2>&1
Write-Log ".NET SDK: $dotnetVersion"
Write-Log "Azure CLI: $azVersion"
Write-Log "Docker: $dockerVersion"

Write-Log "Stage 2 completed successfully"
'@

$stage2Path = "C:\stage2-setup.ps1"
$stage2Content | Out-File -FilePath $stage2Path -Encoding UTF8 -Force

# 시작 프로그램에 Stage2 등록 (우선 방법)
Write-Log "Registering Stage 2 script in startup programs..."
try {
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    $regValue = "PowerShell -ExecutionPolicy Bypass -File `"$stage2Path`""
    Set-ItemProperty -Path $regPath -Name "Stage2Setup" -Value $regValue -Force
    Write-Log "Stage 2 registered in startup programs successfully"
} catch {
    Write-Log "Error registering in startup programs: $($_.Exception.Message)"
    Write-Log "Will try scheduled task as backup..."
    
    # 백업: 작업 스케줄러에 Stage2 등록
    try {
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File $stage2Path"
        $trigger = New-ScheduledTaskTrigger -AtStartup
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        
        Register-ScheduledTask -TaskName "Stage2Setup" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force
        Write-Log "Stage 2 scheduled task registered as backup"
    } catch {
        Write-Log "Error registering scheduled task: $($_.Exception.Message)"
    }
}

# 재부팅 예약
Write-Log "Restarting in 10 seconds..."
shutdown /r /t 10 /c "Restarting for Docker/Hyper-V activation"
 
