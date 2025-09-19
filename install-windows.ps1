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
    "$(Get-Date): 오류 발생 - $($_.Exception.Message)" | Out-File -FilePath "C:\setup-error.txt" -Force
    Write-Host "설정 중 오류 발생"
}
