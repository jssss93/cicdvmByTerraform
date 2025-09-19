# -*- coding: utf-8 -*-
# Windows VM PowerShell DSC 설정
# Azure CLI, .NET SDK, Docker Engine 설치

# PowerShell 콘솔 인코딩 설정
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Configuration VMSetupConfiguration {
    param(
        [string]$CustomScript = "${custom_script}"
    )
    
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName PackageManagement -ModuleVersion 1.0.0.1
    
    Node localhost {
        
        # 로그 파일 생성
        File LogFile {
            DestinationPath = "C:\vm-setup.log"
            Contents = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Windows VM DSC 설정 시작`n"
            Ensure = "Present"
        }
        
        # PowerShell 실행 정책 설정
        Script SetExecutionPolicy {
            SetScript = {
                Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
                Add-Content -Path "C:\vm-setup.log" -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] PowerShell 실행 정책 설정 완료"
            }
            TestScript = {
                $policy = Get-ExecutionPolicy -Scope LocalMachine
                return ($policy -eq "RemoteSigned" -or $policy -eq "Unrestricted")
            }
            GetScript = {
                return @{ Result = (Get-ExecutionPolicy -Scope LocalMachine) }
            }
            DependsOn = "[File]LogFile"
        }
        
        # Chocolatey 설치
        Script InstallChocolatey {
            SetScript = {
                Add-Content -Path "C:\vm-setup.log" -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Chocolatey 설치 시작"
                
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
                iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
                
                # PATH 새로고침
                $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")
                
                Add-Content -Path "C:\vm-setup.log" -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Chocolatey 설치 완료"
            }
            TestScript = {
                return (Get-Command choco -ErrorAction SilentlyContinue) -ne $null
            }
            GetScript = {
                $chocoInstalled = (Get-Command choco -ErrorAction SilentlyContinue) -ne $null
                return @{ Result = $chocoInstalled }
            }
            DependsOn = "[Script]SetExecutionPolicy"
        }
        
        # Azure CLI 설치
        Script InstallAzureCLI {
            SetScript = {
                Add-Content -Path "C:\vm-setup.log" -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Azure CLI 설치 시작"
                choco install azure-cli -y
                Add-Content -Path "C:\vm-setup.log" -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Azure CLI 설치 완료"
            }
            TestScript = {
                return (Get-Command az -ErrorAction SilentlyContinue) -ne $null
            }
            GetScript = {
                $azInstalled = (Get-Command az -ErrorAction SilentlyContinue) -ne $null
                return @{ Result = $azInstalled }
            }
            DependsOn = "[Script]InstallChocolatey"
        }
        
        # .NET 9 SDK 설치
        Script InstallDotNet {
            SetScript = {
                Add-Content -Path "C:\vm-setup.log" -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] .NET 9 SDK 설치 시작"
                choco install dotnet-9.0-sdk -y
                Add-Content -Path "C:\vm-setup.log" -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] .NET 9 SDK 설치 완료"
            }
            TestScript = {
                return (Get-Command dotnet -ErrorAction SilentlyContinue) -ne $null
            }
            GetScript = {
                $dotnetInstalled = (Get-Command dotnet -ErrorAction SilentlyContinue) -ne $null
                return @{ Result = $dotnetInstalled }
            }
            DependsOn = "[Script]InstallAzureCLI"
        }
        
        # Docker Engine 설치
        Script InstallDocker {
            SetScript = {
                Add-Content -Path "C:\vm-setup.log" -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Docker Engine 설치 시작"
                choco install docker-engine -y
                
                # Windows 컨테이너 기능 활성화
                DISM /Online /Enable-Feature /All /FeatureName:Microsoft-Hyper-V /NoRestart
                DISM /Online /Enable-Feature /All /FeatureName:Containers /NoRestart
                
                Add-Content -Path "C:\vm-setup.log" -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Docker Engine 설치 완료"
            }
            TestScript = {
                return (Get-Command docker -ErrorAction SilentlyContinue) -ne $null
            }
            GetScript = {
                $dockerInstalled = (Get-Command docker -ErrorAction SilentlyContinue) -ne $null
                return @{ Result = $dockerInstalled }
            }
            DependsOn = "[Script]InstallDotNet"
        }
        
        # Git 설치
        Script InstallGit {
            SetScript = {
                Add-Content -Path "C:\vm-setup.log" -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Git 설치 시작"
                choco install git -y
                Add-Content -Path "C:\vm-setup.log" -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Git 설치 완료"
            }
            TestScript = {
                return (Get-Command git -ErrorAction SilentlyContinue) -ne $null
            }
            GetScript = {
                $gitInstalled = (Get-Command git -ErrorAction SilentlyContinue) -ne $null
                return @{ Result = $gitInstalled }
            }
            DependsOn = "[Script]InstallDocker"
        }
        
        # 사용자 정의 스크립트 실행
        Script CustomScript {
            SetScript = {
                if ("$CustomScript" -and "$CustomScript".Trim() -ne "") {
                    Add-Content -Path "C:\vm-setup.log" -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] 사용자 정의 스크립트 실행 시작"
                    try {
                        Invoke-Expression "$CustomScript"
                        Add-Content -Path "C:\vm-setup.log" -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] 사용자 정의 스크립트 실행 완료"
                    } catch {
                        Add-Content -Path "C:\vm-setup.log" -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] 사용자 정의 스크립트 실행 오류: $($_.Exception.Message)"
                    }
                }
            }
            TestScript = {
                return $true  # 항상 실행
            }
            GetScript = {
                return @{ Result = "CustomScript" }
            }
            DependsOn = "[Script]InstallGit"
        }
        
        # 설치 완료 마커 파일 생성
        File SetupCompleteMarker {
            DestinationPath = "C:\vm-setup-complete.txt"
            Contents = "VM 초기 설정 완료: $(Get-Date)`n설치된 소프트웨어: Azure CLI, .NET 9 SDK, Docker Engine, Git`n활성화된 기능: Hyper-V, Windows 컨테이너"
            Ensure = "Present"
            DependsOn = "[Script]CustomScript"
        }
        
        # 최종 로그 작성
        Script FinalLog {
            SetScript = {
                Add-Content -Path "C:\vm-setup.log" -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] 모든 DSC 설정 완료"
                Add-Content -Path "C:\vm-setup.log" -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Hyper-V 및 컨테이너 기능 활성화를 위해 재부팅이 필요합니다"
            }
            TestScript = {
                return $false  # 항상 실행
            }
            GetScript = {
                return @{ Result = "FinalLog" }
            }
            DependsOn = "[File]SetupCompleteMarker"
        }
    }
}

# DSC 설정 적용
VMSetupConfiguration -OutputPath "C:\DSC"
Start-DscConfiguration -Path "C:\DSC" -Wait -Verbose -Force
