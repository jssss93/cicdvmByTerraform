# Azure VM Terraform 프로젝트 - 환경별 배포

이 프로젝트는 Terraform을 사용하여 Azure에 Windows Server 2022 Datacenter와 Ubuntu 24.04 가상머신을 **환경별로** 생성하고 관리합니다. 
코드는 재사용 가능한 모듈로 구성되어 있어 유지보수와 확장이 용이하며, 개발/POC 환경을 독립적으로 관리할 수 있습니다.

## ✨ 주요 기능

### 🤖 자동화된 소프트웨어 설치
- **Windows VM**: PowerShell 스크립트를 통한 자동 설치
  - Docker & Docker Compose
  - Azure CLI
  - Git 및 개발 도구
  - GitHub Actions Runner (Windows Service로 자동 등록)
  
- **Linux VM**: Cloud-init을 통한 자동 설치
  - Docker & Docker Compose
  - Azure CLI (Ubuntu 24.04 호환)
  - 개발 도구 (htop, tree, vim, nano, net-tools)
  - GitHub Actions Runner (systemd 서비스로 자동 등록)

### 🔄 중복 실행 방지 (Idempotency)
- 파일 존재 확인으로 재설치 방지
- 서비스 중복 생성 방지
- 설정 중복 실행 방지

### 🛡️ 강화된 보안
- 네트워크 보안 그룹 자동 구성
- SSH/RDP 포트 자동 개방
- 환경별 접근 제어

### 🌐 모듈화된 네트워크 관리
- **Public IP**: Windows/Linux VM별 개별 PIP 생성
- **서브넷**: 기존 서브넷 활용 또는 새로 생성
- **NSG**: 환경별 독립적인 보안 그룹

### 📊 통합 진단 설정
- **Log Analytics**: VM 및 네트워크 리소스 로그 수집
- **메트릭 수집**: Azure Monitor를 통한 성능 모니터링
- **비용 최적화**: 불필요한 리소스 제거

## 🏗️ 프로젝트 구조

```
cicdTerraform/
├── environments/                    # 환경별 설정 파일
│   ├── dev/                        # 개발 환경
│   │   └── terraform.tfvars
│   └── poc/                        # POC 환경
│       └── terraform.tfvars
├── modules/                        # 재사용 가능한 Terraform 모듈
│   ├── linux-vm/                  # Linux VM 모듈
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── variables.tf
│   │   └── scripts/
│   │       ├── cloud-init.yaml    # Cloud-init 자동화 스크립트
│   │       └── install-linux.sh   # Linux 설치 스크립트
│   ├── windows-vm/                # Windows VM 모듈
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── network/                   # 네트워크 모듈
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── variables.tf
│   │   └── public-ip/             # Public IP 서브모듈
│   │       ├── main.tf
│   │       ├── outputs.tf
│   │       └── variables.tf
│   └── diagnostic/                # 진단 설정 모듈
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
├── main.tf                        # 메인 구성 파일
├── variables.tf                   # 입력 변수 정의
├── outputs.tf                     # 출력 변수 정의
├── install-windows-en.ps1         # Windows VM 자동화 스크립트
└── README.md                      # 프로젝트 문서
```

## 🌍 환경별 설정

### 개발 환경 (dev)
- **VM 크기**: Standard_D2s_v3 (2 vCPU, 8 GiB RAM)
- **디스크**: 128 GiB OS 디스크만 사용
- **리소스**: 개발/테스트용 최소 구성
- **데이터 디스크**: 사용하지 않음 (비용 절약)

### POC 환경 (poc)
- **VM 크기**: Standard_D4s_v3 (4 vCPU, 16 GiB RAM)
- **디스크**: 128 GiB OS 디스크만 사용
- **리소스**: Proof of Concept 검증용 구성
- **데이터 디스크**: 사용하지 않음 (비용 절약)

## 🚀 빠른 시작

### 1. 사전 요구사항

```bash
# Terraform 설치 확인
terraform version

# Azure CLI 설치 확인
az --version

# Azure 로그인
az login
```

### 2. 환경별 배포 (Terraform Workspace 사용)

**⚠️ 중요**: 환경별로 state 파일을 분리하기 위해 Terraform Workspace를 사용합니다.

```bash
# 1. 초기화 (최초 1회)
terraform init

# 2. 환경별 workspace 생성 (최초 1회)
terraform workspace new dev
terraform workspace new poc

# 3. 개발 환경 배포
terraform workspace select dev
terraform plan -var-file=environments/dev/terraform.tfvars
terraform apply -var-file=environments/dev/terraform.tfvars


# 5. POC 환경 배포
terraform workspace select poc
terraform plan -var-file=environments/poc/terraform.tfvars
terraform apply -var-file=environments/poc/terraform.tfvars
```

### 3. 환경별 리소스 삭제

```bash
# 개발 환경 삭제
terraform workspace select dev
terraform destroy -var-file=environments/dev/terraform.tfvars


# POC 환경 삭제
terraform workspace select poc
terraform destroy -var-file=environments/poc/terraform.tfvars
```

## 📋 환경별 명령어 가이드

### Workspace 관리

```bash
# 현재 workspace 확인
terraform workspace show

# 모든 workspace 목록 확인
terraform workspace list

# workspace 전환
terraform workspace select {환경}
```

### 기본 명령어 패턴

```bash
# 1. workspace 전환 (필수!)
terraform workspace select {환경}

# 2. 계획 확인
terraform plan -var-file=environments/{환경}/terraform.tfvars

# 3. 배포 실행
terraform apply -var-file=environments/{환경}/terraform.tfvars

# 4. 리소스 삭제
terraform destroy -var-file=environments/{환경}/terraform.tfvars

# 5. 구문 검증
terraform validate
```

### 환경별 예시

```bash
# 개발 환경
terraform workspace select dev
terraform plan -var-file=environments/dev/terraform.tfvars
terraform apply -var-file=environments/dev/terraform.tfvars


# POC 환경
terraform workspace select poc
terraform plan -var-file=environments/poc/terraform.tfvars
terraform apply -var-file=environments/poc/terraform.tfvars
```

## 🔄 일반적인 워크플로우

### 개발 환경에서 시작

```bash
# 1. 초기화
terraform init

# 2. 개발 workspace 생성 및 전환
terraform workspace new dev
terraform workspace select dev

# 3. 개발 환경 계획 확인
terraform plan -var-file=environments/dev/terraform.tfvars

# 4. 개발 환경 배포
terraform apply -var-file=environments/dev/terraform.tfvars

# 5. 연결 정보 확인
terraform output -raw windows_rdp_connection
terraform output -raw linux_ssh_connection
```


### POC 환경 배포

```bash
# 1. POC workspace 생성 및 전환
terraform workspace new poc
terraform workspace select poc

# 2. POC 환경 계획 확인
terraform plan -var-file=environments/poc/terraform.tfvars

# 3. POC 환경 배포
terraform apply -var-file=environments/poc/terraform.tfvars
```

## ⚙️ 환경별 설정 커스터마이징

각 환경의 설정을 수정하려면 해당 환경의 `terraform.tfvars` 파일을 편집하세요:

```bash
# 개발 환경 설정 편집
vi environments/dev/terraform.tfvars


# POC 환경 설정 편집
vi environments/poc/terraform.tfvars
```

### 주요 설정 항목

```hcl
# 환경 설정
environment = "dev"  # dev, staging, prod

# 리소스 그룹
existing_resource_group_name = "rg-az01-dev-hyundai.teams-01"

# 네트워킹
existing_vnet_name = "ict-dev-kttranslator-vnet-kc"
existing_subnet_name = "subnet-computing"

# VM 설정
vm_name_prefix = "ict-dev-kttranslator-cicivm01-kc"
windows_vm_size = "Standard_D2s_v3"  # 환경별로 조정
linux_vm_size = "Standard_D2s_v3"

```

## 🔐 보안 고려사항

### 환경별 접근 제어

```hcl
# 개발 환경 - 제한된 IP 접근
existing_nsg_name = "dev-restricted-nsg"

# 프로덕션 환경 - 엄격한 보안
existing_nsg_name = "prod-secure-nsg"
```

## 📊 생성되는 리소스

### 각 환경별로 생성되는 리소스

- **Windows VM**: Windows Server 2022 Datacenter
- **Linux VM**: Ubuntu 24.04 LTS
- **Public IP**: Windows/Linux VM별 개별 고정 공용 IP
- **Network Interface**: VM별 네트워크 인터페이스
- **Network Security Group**: 환경별 독립적인 보안 그룹
- **Log Analytics Workspace**: 통합 로그 수집 (기존 활용)
- **진단 설정**: VM 및 네트워크 리소스 모니터링

### 비용 최적화
- **데이터 디스크**: 사용하지 않음 (OS 디스크만 사용)
- **VM 크기**: 개발 환경은 Standard_D2s_v3 (2 vCPU, 8GB RAM)
- **스토리지**: Premium SSD (고성능 필요시)

## 🔍 연결 및 접근

### 환경별 연결 정보 확인

```bash
# 개발 환경 연결 정보
terraform workspace select dev
terraform output -raw windows_rdp_connection
terraform output -raw linux_ssh_connection

terraform output -raw windows_rdp_connection
terraform output -raw linux_ssh_connection

# POC 환경 연결 정보
terraform workspace select poc
terraform output -raw windows_rdp_connection
terraform output -raw linux_ssh_connection
```

### 환경별 상태 관리

```bash
# 현재 workspace 확인
terraform workspace show

# 현재 환경의 상태 확인
terraform show

# 모든 출력값 확인
terraform output

# 특정 출력값 확인
terraform output windows_vm_names
terraform output linux_vm_names

# 환경별 리소스 목록 확인
terraform workspace select dev
terraform state list

terraform state list

terraform workspace select poc
terraform state list
```

### VM 접속 방법

**Windows VM (RDP)**
- 사용자명: `azureuser`
- 비밀번호: `terraform output -raw admin_password`
- 연결: `terraform output -raw windows_rdp_connection`
- **자동 설치 확인**: `C:\vm-setup.log` 파일 확인

**Linux VM (SSH)**  
- 사용자명: `azureuser`
- 비밀번호: `terraform output -raw admin_password`
- 연결: `terraform output -raw linux_ssh_connection`
- **자동 설치 확인**: `sudo cat /var/log/vm-setup.log`

### 📦 설치된 소프트웨어 확인

**Windows VM에서**
```powershell
# Docker 확인
docker --version

# Azure CLI 확인  
az --version

# GitHub Actions Runner 서비스 확인
Get-Service -Name "GitHubActionsRunner"

# 설치 로그 확인
Get-Content C:\vm-setup.log
```

**Linux VM에서**
```bash
# Docker 확인
docker --version

# Azure CLI 확인
az --version

# GitHub Actions Runner 서비스 확인
sudo systemctl status github-actions-runner

# 설치 로그 확인
sudo cat /var/log/vm-setup.log

# Cloud-init 상태 확인
sudo cloud-init status --long
```

### 🔧 GitHub Actions Runner 설정

**설치 경로 및 설정**
- **Windows**: `C:\actions-runner\`
- **Linux**: `/home/azureuser/actions-runner/`

**GitHub Repository**: `https://github.com/axd-project-hyundai`

**Runner 설정**
- **Runner Name**: 
  - Windows: `windows-runner-01`
  - Linux: `linux-runner-01`
- **Labels**: 
  - Windows: `windows,self-hosted,x64,windows-server-2022`
  - Linux: `linux,self-hosted,x64,ubuntu-24.04`
- **Runner Group**: `Default`

## 🛠️ 트러블슈팅

### 일반적인 문제

1. **환경 설정 오류**
   ```bash
   # 환경별 설정 파일 존재 확인
   ls environments/dev/terraform.tfvars
   ls environments/poc/terraform.tfvars
   
   # 설정 파일 내용 확인
   cat environments/dev/terraform.tfvars
   ```

2. **Azure 인증 오류**
   ```bash
   az login
   az account show
   az account list --output table
   ```

3. **리소스 이름 충돌**
   - 각 환경별로 고유한 이름 사용
   - 환경별 접두사 확인 (`ict-dev-`, `ict-poc-`)

4. **Workspace 관련 오류**
   ```bash
   # 현재 workspace 확인
   terraform workspace show
   
   # 모든 workspace 목록 확인
   terraform workspace list
   
   # 올바른 workspace로 전환
   terraform workspace select dev
   ```

5. **Terraform 상태 오류**
   ```bash
   # 상태 파일 확인 (workspace별)
   ls -la .terraform/
   ls -la terraform.tfstate.d/
   
   # 상태 새로고침
   terraform workspace select dev
   terraform refresh -var-file=environments/dev/terraform.tfvars
   
   # 상태 가져오기
   terraform import -var-file=environments/dev/terraform.tfvars
   ```

### 🚨 자동화 스크립트 관련 문제

6. **SSH 접속 불가 (Linux VM)**
   ```bash
   # 네트워크 보안 그룹에 SSH 규칙 추가
   az network nsg rule create \
     --resource-group rg-az01-poc-hyundai.teams-01 \
     --nsg-name ict-dev-kttranslator-compute-nsg-kc \
     --name SSH \
     --priority 110 \
     --destination-port-ranges 22 \
     --access Allow \
     --protocol Tcp
   ```

7. **Cloud-init 실행 실패**
   ```bash
   # VM에서 직접 확인 (Azure Run Command 사용)
   az vm run-command invoke \
     --resource-group rg-az01-poc-hyundai.teams-01 \
     --name ict-dev-kttranslator-linuxvm01-kc \
     --command-id RunShellScript \
     --scripts "cloud-init status --long"
   
   # Cloud-init 로그 확인
   az vm run-command invoke \
     --resource-group rg-az01-poc-hyundai.teams-01 \
     --name ict-dev-kttranslator-linuxvm01-kc \
     --command-id RunShellScript \
     --scripts "cat /var/log/cloud-init.log"
   ```

8. **GitHub Actions Runner 설치 실패**
   ```bash
   # Windows VM - PowerShell 스크립트 실행 상태 확인
   # RDP 접속 후
   Get-Content C:\vm-setup.log | Select-String "GitHub"
   
   # Linux VM - 서비스 상태 확인
   sudo systemctl status github-actions-runner
   sudo journalctl -u github-actions-runner -f
   ```

9. **Docker 설치 실패**
   ```bash
   # Windows VM
   docker --version
   Get-Service docker
   
   # Linux VM  
   docker --version
   sudo systemctl status docker
   ```

10. **YAML 구문 오류 (Cloud-init)**
    ```bash
    # YAML 구문 검증
    sudo cloud-init schema --system
    
    # Cloud-init 재실행 (테스트용)
    sudo cloud-init clean
    sudo cloud-init init
    ```

### 로그 확인

```bash
# 상세 로그로 문제 진단
export TF_LOG=DEBUG
terraform apply -var-file=environments/dev/terraform.tfvars
```

## 💰 비용 최적화

### 환경별 비용 관리

- **개발**: 작은 VM 크기, 필요시에만 실행
- **POC**: Proof of Concept 검증용 구성

### 비용 절약 팁

```bash
# 개발 환경 리소스 삭제 (비용 절약)
terraform workspace select dev
terraform destroy -var-file=environments/dev/terraform.tfvars


# 자동 승인으로 삭제 (주의!)
terraform workspace select dev
terraform destroy -var-file=environments/dev/terraform.tfvars -auto-approve
```
