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
    
    # 수동 설정 가이드 생성
    $manualSetupGuide = @"
MANUAL SETUP GUIDE
==================

If automatic setup fails, follow these manual steps:

1. Fix temporary folder permissions (Run as Administrator):
   # Create DISM-specific temp directories
   New-Item -Path "C:\DISM_Temp" -ItemType Directory -Force
   New-Item -Path "C:\DISM_Logs" -ItemType Directory -Force
   
   # Set proper permissions
   icacls "C:\DISM_Temp" /grant SYSTEM:F /T
   icacls "C:\DISM_Temp" /grant Administrators:F /T
   icacls "C:\Windows\Temp" /grant SYSTEM:F /T

2. Enable Windows Features with custom temp directory (Run as Administrator):
   dism /online /enable-feature /featurename:Containers /all /norestart /ScratchDir:C:\DISM_Temp /LogPath:C:\DISM_Logs\container.log
   dism /online /enable-feature /featurename:Microsoft-Hyper-V /all /norestart /ScratchDir:C:\DISM_Temp /LogPath:C:\DISM_Logs\hyperv.log

3. Alternative PowerShell method if DISM fails:
   Enable-WindowsOptionalFeature -Online -FeatureName containers -All -NoRestart
   Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart

4. Environment variable method as last resort:
   $env:TEMP = "C:\DISM_Temp"
   $env:TMP = "C:\DISM_Temp"
   Enable-WindowsOptionalFeature -Online -FeatureName containers -All -NoRestart
   Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart

5. Restart the server:
   shutdown /r /t 0

6. After restart, start Docker services:
   net start docker
   net start com.docker.service

7. Verify Docker is working:
   docker --version
   docker info

8. Configure GitHub Actions Runner:
   cd C:\actions-runner
   .\config.cmd --url https://github.com/your-org/your-repo --token YOUR_TOKEN
   .\svc.cmd install
   .\svc.cmd start

9. Check service status:
   .\svc.cmd status
"@

    $manualSetupGuide | Out-File -FilePath "C:\MANUAL_SETUP_GUIDE.txt" -Force
    Write-Log "MANUAL_SETUP_GUIDE.txt created in C:\"
} catch {
    Write-Log "Error installing GitHub Actions Runner: $($_.Exception.Message)"
}

# Windows 기능 활성화 (Azure Script Extension 최적화)
Write-Log "Enabling Windows Container and Hyper-V features using DISM..."

# 임시 폴더 설정 및 권한 문제 해결
Write-Log "Setting up temporary folder and permissions for DISM operations..."
try {
    # 시스템 프로필의 임시 폴더 경로 확인 및 생성
    $systemTempPath = "C:\Windows\system32\config\systemprofile\AppData\Local\Temp"
    if (!(Test-Path $systemTempPath)) {
        Write-Log "Creating system temp directory: $systemTempPath"
        New-Item -Path $systemTempPath -ItemType Directory -Force | Out-Null
    }
    
    # 일반 사용자 임시 폴더도 확인
    $userTempPath = $env:TEMP
    if (!(Test-Path $userTempPath)) {
        Write-Log "Creating user temp directory: $userTempPath"
        New-Item -Path $userTempPath -ItemType Directory -Force | Out-Null
    }
    
    # DISM 캐시 폴더 정리 및 설정
    $dismCachePath = "C:\Windows\Temp\DISM"
    if (!(Test-Path $dismCachePath)) {
        Write-Log "Creating DISM cache directory: $dismCachePath"
        New-Item -Path $dismCachePath -ItemType Directory -Force | Out-Null
    }
    
    # 임시 폴더 권한 설정
    Write-Log "Setting permissions on temporary folders..."
    try {
        # 시스템 계정에 대한 권한 설정
        $acl = Get-Acl $systemTempPath
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
        $acl.SetAccessRule($accessRule)
        Set-Acl -Path $systemTempPath -AclObject $acl
        
        $acl = Get-Acl $dismCachePath
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
        $acl.SetAccessRule($accessRule)
        Set-Acl -Path $dismCachePath -AclObject $acl
        
        Write-Log "Temporary folder permissions configured successfully"
    } catch {
        Write-Log "Warning: Could not set permissions on temp folders: $($_.Exception.Message)"
    }
    
    # DISM 캐시 정리
    Write-Log "Cleaning DISM cache..."
    try {
        & C:\Windows\System32\dism.exe /online /cleanup-image /startcomponentcleanup /resetbase
        Write-Log "DISM cache cleanup completed"
    } catch {
        Write-Log "DISM cache cleanup failed (this is usually not critical): $($_.Exception.Message)"
    }
    
} catch {
    Write-Log "Warning: Error setting up temporary folders: $($_.Exception.Message)"
    Write-Log "Continuing with DISM operations anyway..."
}

try {
    # DISM을 위한 전용 임시 폴더 설정
    $dismTempDir = "C:\DISM_Temp"
    if (!(Test-Path $dismTempDir)) {
        New-Item -Path $dismTempDir -ItemType Directory -Force | Out-Null
        Write-Log "Created DISM temporary directory: $dismTempDir"
    }
    
    # DISM 로그 폴더 설정
    $dismLogDir = "C:\DISM_Logs"
    if (!(Test-Path $dismLogDir)) {
        New-Item -Path $dismLogDir -ItemType Directory -Force | Out-Null
        Write-Log "Created DISM log directory: $dismLogDir"
    }
    
    # DISM 임시 폴더 권한 설정
    try {
        $acl = Get-Acl $dismTempDir
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
        $acl.SetAccessRule($accessRule)
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
        $acl.SetAccessRule($accessRule)
        Set-Acl -Path $dismTempDir -AclObject $acl
        Write-Log "Set permissions on DISM temporary directory"
    } catch {
        Write-Log "Warning: Could not set permissions on DISM temp directory: $($_.Exception.Message)"
    }
    
    # Azure Script Extension에서 안정적인 DISM 실행 (ScratchDir와 LogPath 지정)
    Write-Log "Enabling Container feature using DISM with custom temp directory and logging..."
    $containerArgs = @(
        "/online",
        "/enable-feature",
        "/featurename:Containers",
        "/all",
        "/norestart",
        "/quiet",
        "/ScratchDir:$dismTempDir",
        "/LogPath:$dismLogDir\container-feature.log"
    )
    $containerProcess = Start-Process -FilePath "C:\Windows\System32\dism.exe" -ArgumentList $containerArgs -Wait -NoNewWindow -PassThru
    Write-Log "Container feature DISM completed with exit code: $($containerProcess.ExitCode)"
    
    Write-Log "Enabling Hyper-V feature using DISM with custom temp directory and logging..."
    $hyperVArgs = @(
        "/online",
        "/enable-feature",
        "/featurename:Microsoft-Hyper-V",
        "/all",
        "/norestart",
        "/quiet",
        "/ScratchDir:$dismTempDir",
        "/LogPath:$dismLogDir\hyperv-feature.log"
    )
    $hyperVProcess = Start-Process -FilePath "C:\Windows\System32\dism.exe" -ArgumentList $hyperVArgs -Wait -NoNewWindow -PassThru
    Write-Log "Hyper-V feature DISM completed with exit code: $($hyperVProcess.ExitCode)"
    
    Write-Log "Windows Features configuration completed using DISM"
} catch {
    Write-Log "Error enabling Windows features with DISM: $($_.Exception.Message)"
    Write-Log "Features may need to be enabled manually or after reboot"
    
    # 백업 방법 1: 직접 DISM 명령어 실행 (ScratchDir 지정)
    try {
        Write-Log "Trying direct DISM commands as backup with custom temp directory..."
        $dismTempDir = "C:\DISM_Temp"
        $dismLogDir = "C:\DISM_Logs"
        
        # Container 기능
        & C:\Windows\System32\dism.exe /online /enable-feature /featurename:Containers /all /norestart /quiet /ScratchDir:$dismTempDir /LogPath:$dismLogDir\container-backup.log
        
        # Hyper-V 기능
        & C:\Windows\System32\dism.exe /online /enable-feature /featurename:Microsoft-Hyper-V /all /norestart /quiet /ScratchDir:$dismTempDir /LogPath:$dismLogDir\hyperv-backup.log
        
        Write-Log "Direct DISM commands completed"
    } catch {
        Write-Log "Direct DISM commands also failed: $($_.Exception.Message)"
        
        # 백업 방법 2: PowerShell Enable-WindowsOptionalFeature 사용
        try {
            Write-Log "Trying PowerShell Enable-WindowsOptionalFeature as final backup..."
            Enable-WindowsOptionalFeature -Online -FeatureName containers -All -NoRestart -ErrorAction SilentlyContinue
            Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart -ErrorAction SilentlyContinue
            Write-Log "PowerShell Windows features commands completed"
        } catch {
            Write-Log "PowerShell Windows features commands also failed: $($_.Exception.Message)"
            
            # 백업 방법 3: 환경 변수 설정 후 재시도
            try {
                Write-Log "Trying with custom environment variables as final attempt..."
                $originalTemp = $env:TEMP
                $originalTmp = $env:TMP
                
                $env:TEMP = "C:\DISM_Temp"
                $env:TMP = "C:\DISM_Temp"
                
                Enable-WindowsOptionalFeature -Online -FeatureName containers -All -NoRestart -ErrorAction SilentlyContinue
                Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart -ErrorAction SilentlyContinue
                
                # 환경 변수 복원
                $env:TEMP = $originalTemp
                $env:TMP = $originalTmp
                
                Write-Log "Environment variable method completed"
            } catch {
                Write-Log "All methods failed: $($_.Exception.Message)"
                Write-Log "Windows features will need to be enabled manually after reboot"
            }
        }
    }
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
    $containerFeature = Get-WindowsOptionalFeature -Online -FeatureName containers -ErrorAction SilentlyContinue
    $hyperVFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -ErrorAction SilentlyContinue
    
    if ($containerFeature) {
        Write-Log "Container feature status: $($containerFeature.State)"
    } else {
        Write-Log "Container feature status: Not found"
    }
    
    if ($hyperVFeature) {
        Write-Log "Hyper-V feature status: $($hyperVFeature.State)"
    } else {
        Write-Log "Hyper-V feature status: Not found"
    }
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
 
