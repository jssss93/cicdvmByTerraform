# 로그 함수 정의
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage
    Add-Content -Path "C:\vm-setup.log" -Value $logMessage -Force
}

Write-Log "Windows VM setup started"
Write-Log "Installing software packages..."

# SYSTEM 계정 임시 폴더 생성
$systemTempPath = "C:\Windows\system32\config\systemprofile\AppData\Local\Temp"
if (!(Test-Path $systemTempPath)) {
    Write-Log "Creating SYSTEM temp directory..."
    New-Item -Path $systemTempPath -ItemType Directory -Force -ErrorAction SilentlyContinue
} else {
    Write-Log "SYSTEM temp directory already exists"
}

# 대체 임시 폴더 설정
$env:TEMP = "C:\Windows\Temp"
$env:TMP = "C:\Windows\Temp"
Write-Log "Set temporary folder to C:\Windows\Temp"

Set-ExecutionPolicy Bypass -Scope Process -Force
Write-Log "PowerShell execution policy set to Bypass"

try {
    # Install Chocolatey
    Write-Log "Installing Chocolatey..."
    # Chocolatey 설치를 위한 환경 변수 설정
    $env:chocolateyUseWindowsCompression = 'true'
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Write-Log "Chocolatey installation completed"
    
    # Refresh PATH
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")
    Write-Log "PATH environment variable refreshed"
    
    # Install .NET 9 SDK
    Write-Log "Installing .NET 9 SDK..."
    choco install dotnet-9.0-sdk -y --force
    Write-Log ".NET 9 SDK installation completed"
    
    # Install Docker Engine
    Write-Log "Installing Docker Engine..."
    choco install docker-engine -y --force
    Write-Log "Docker Engine installation completed"
    
    # Enable Windows containers feature
    Write-Log "Enabling Windows containers feature..."
    Enable-WindowsOptionalFeature -Online -FeatureName containers -All -NoRestart
    Write-Log "Windows containers feature enabled"
    
    # Enable Hyper-V (required for Docker)
    Write-Log "Enabling Hyper-V feature..."
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart
    Write-Log "Hyper-V feature enabled"
    
    # Start Docker service
    Write-Log "Starting Docker service..."
    Start-Service -Name "docker" -ErrorAction SilentlyContinue
    Write-Log "Docker service start attempted"
    
    # Verify installations
    Write-Log "Verifying installations..."
    $dotnetVersion = & dotnet --version 2>&1
    $dockerVersion = & docker --version 2>&1
    
    Write-Log ".NET 9 SDK version: $dotnetVersion"
    Write-Log "Docker version: $dockerVersion"
    
    $results = @"
$(Get-Date): Installation completed
.NET 9 SDK: $dotnetVersion
Docker: $dockerVersion
"@
    
    $results | Out-File -FilePath "C:\setup-complete.txt" -Force
    Write-Log "Setup completed successfully with Docker Engine"
    Write-Log "Installation results saved to C:\setup-complete.txt"
    
    # Schedule restart after 2 minutes to allow script completion
    Write-Log "Scheduling restart in 2 minutes for Hyper-V and Docker activation..."
    "$(Get-Date): Restart scheduled for Hyper-V and Docker activation" | Out-File -FilePath "C:\restart-scheduled.txt" -Force
    shutdown /r /t 120 /c "Restarting for Hyper-V and Docker activation"
    Write-Log "Restart scheduled in 2 minutes"
    
} catch {
    Write-Log "Error occurred during setup: $($_.Exception.Message)"
    Write-Log "Stack trace: $($_.ScriptStackTrace)"
    "$(Get-Date): Error occurred - $($_.Exception.Message)" | Out-File -FilePath "C:\setup-error.txt" -Force
    Write-Log "Error details saved to C:\setup-error.txt"
}

Write-Log "Script execution completed"
