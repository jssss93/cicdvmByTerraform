Write-Host "Windows VM setup started"
"$(Get-Date): Windows VM setup started" | Out-File -FilePath "C:\vm-setup.log" -Force
Write-Host "Installing software packages..."
Set-ExecutionPolicy Bypass -Scope Process -Force

try {
    # Install Chocolatey
    Write-Host "Installing Chocolatey..."
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    
    # Refresh PATH
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")
    
    # Install Azure CLI
    Write-Host "Installing Azure CLI..."
    choco install azure-cli -y --force
    
    # Install .NET 9 SDK
    Write-Host "Installing .NET 9 SDK..."
    choco install dotnet-9.0-sdk -y --force
    
    # Install Docker Engine
    Write-Host "Installing Docker Engine..."
    choco install docker-engine -y --force
    
    # Enable Windows containers feature
    Write-Host "Enabling Windows containers feature..."
    Enable-WindowsOptionalFeature -Online -FeatureName containers -All -NoRestart
    
    # Enable Hyper-V (required for Docker)
    Write-Host "Enabling Hyper-V feature..."
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart
    
    # Start Docker service
    Write-Host "Starting Docker service..."
    Start-Service -Name "docker" -ErrorAction SilentlyContinue
    
    # Verify installations
    Write-Host "Verifying installations..."
    $azVersion = & az version --output tsv 2>&1
    $dotnetVersion = & dotnet --version 2>&1
    $dockerVersion = & docker --version 2>&1
    
    $results = @"
$(Get-Date): Installation completed
Azure CLI: $($azVersion -split "`n" | Select-Object -First 1)
.NET 9 SDK: $dotnetVersion
Docker: $dockerVersion
"@
    
    $results | Out-File -FilePath "C:\setup-complete.txt" -Force
    Write-Host "Setup completed successfully with Docker Engine"
    
    # Schedule restart after 2 minutes to allow script completion
    Write-Host "Scheduling restart in 2 minutes for Hyper-V and Docker activation..."
    "$(Get-Date): Restart scheduled for Hyper-V and Docker activation" | Out-File -FilePath "C:\restart-scheduled.txt" -Force
    shutdown /r /t 120 /c "Restarting for Hyper-V and Docker activation"
    
} catch {
    "$(Get-Date): Error occurred - $($_.Exception.Message)" | Out-File -FilePath "C:\setup-error.txt" -Force
    Write-Host "Error occurred during setup"
}
