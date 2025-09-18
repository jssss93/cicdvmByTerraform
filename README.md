# Azure VM Terraform 프로젝트 - 환경별 배포

이 프로젝트는 Terraform을 사용하여 Azure에 Windows Server 2022 Datacenter와 Ubuntu 24.04 가상머신을 **환경별로** 생성하고 관리합니다. 
코드는 재사용 가능한 모듈로 구성되어 있어 유지보수와 확장이 용이하며, 개발/HMC/POC 환경을 독립적으로 관리할 수 있습니다.

## 🏗️ 프로젝트 구조

```
cicdTerraform/
├── environments/                    # 환경별 설정 파일
│   ├── dev/                        # 개발 환경
│   │   └── terraform.tfvars
│   ├── hmc/                        # HMC 환경  
│   │   └── terraform.tfvars
│   └── poc/                        # POC 환경
│       └── terraform.tfvars
├── modules/                        # 재사용 가능한 Terraform 모듈
│   ├── compute-gallery/           # Azure Compute Gallery 모듈
│   └── virtual-machines/          # 가상머신 모듈
├── main.tf                        # 메인 구성 파일
├── variables.tf                   # 입력 변수 정의
├── outputs.tf                     # 출력 변수 정의
├── terraform.tfvars.example       # 설정 예제 파일
└── README.md                      # 프로젝트 문서
```

## 🌍 환경별 설정

### 개발 환경 (dev)
- **VM 크기**: Standard_D4s_v3 (4 vCPU, 16 GiB RAM)
- **디스크**: 128 GiB OS, 32 GiB 데이터 디스크
- **리소스**: 개발/테스트용 최소 구성

### HMC 환경 (hmc)
- **VM 크기**: Standard_D4s_v3 (4 vCPU, 16 GiB RAM)
- **디스크**: 128 GiB OS, 32 GiB 데이터 디스크
- **리소스**: HMC 시스템용 중간 구성

### POC 환경 (poc)
- **VM 크기**: Standard_D4s_v3 (4 vCPU, 16 GiB RAM)
- **디스크**: 128 GiB OS, 32 GiB 데이터 디스크
- **리소스**: Proof of Concept 검증용 구성

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
terraform workspace new hmc
terraform workspace new poc

# 3. 개발 환경 배포
terraform workspace select dev
terraform plan -var-file=environments/dev/terraform.tfvars
terraform apply -var-file=environments/dev/terraform.tfvars

# 4. HMC 환경 배포
terraform workspace select hmc
terraform plan -var-file=environments/hmc/terraform.tfvars
terraform apply -var-file=environments/hmc/terraform.tfvars

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

# HMC 환경 삭제  
terraform workspace select hmc
terraform destroy -var-file=environments/hmc/terraform.tfvars

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

# HMC 환경
terraform workspace select hmc
terraform plan -var-file=environments/hmc/terraform.tfvars
terraform apply -var-file=environments/hmc/terraform.tfvars

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

### HMC 환경으로 승격

```bash
# 1. HMC workspace 생성 및 전환
terraform workspace new hmc
terraform workspace select hmc

# 2. HMC 환경 계획 확인
terraform plan -var-file=environments/hmc/terraform.tfvars

# 3. HMC 환경 배포
terraform apply -var-file=environments/hmc/terraform.tfvars
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

# HMC 환경 설정 편집
vi environments/hmc/terraform.tfvars

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
windows_vm_size = "Standard_D4s_v3"  # 환경별로 조정
linux_vm_size = "Standard_D4s_v3"

# 디스크 설정
os_disk_size_gb = 128  # 환경별로 조정
data_disk_size_gb = 32  # 환경별로 조정

# 갤러리 설정
gallery_name = "ict-dev-kttranslator-cg-kc"
```

## 🔐 보안 고려사항

### 환경별 접근 제어

```hcl
# 개발 환경 - 제한된 IP 접근
existing_nsg_name = "dev-restricted-nsg"

# 프로덕션 환경 - 엄격한 보안
existing_nsg_name = "prod-secure-nsg"
```

### 비밀번호 관리

```hcl
# 환경별로 다른 강력한 비밀번호 설정
admin_password = "DevPassword123!"      # 개발
admin_password = "StagingPassword123!"  # 스테이징  
admin_password = "ProdPassword123!"     # 프로덕션
```

## 📊 생성되는 리소스

### 각 환경별로 생성되는 리소스

- **Azure Compute Gallery**: 사용자 정의 VM 이미지 관리
- **Windows VM**: Windows Server 2022 Datacenter
- **Linux VM**: Ubuntu 24.04 LTS
- **Public IP**: 각 VM별 고정 공용 IP
- **Network Interface**: VM별 네트워크 인터페이스
- **데이터 디스크**: VM별 추가 스토리지

## 🔍 연결 및 접근

### 환경별 연결 정보 확인

```bash
# 개발 환경 연결 정보
terraform workspace select dev
terraform output -raw windows_rdp_connection
terraform output -raw linux_ssh_connection

# HMC 환경 연결 정보
terraform workspace select hmc
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

terraform workspace select hmc
terraform state list

terraform workspace select poc
terraform state list
```

### VM 접속 방법

**Windows VM (RDP)**
- 사용자명: `azureuser`
- 비밀번호: `terraform output -raw admin_password`
- 연결: `terraform output -raw windows_rdp_connection`

**Linux VM (SSH)**  
- 사용자명: `azureuser`
- 비밀번호: `terraform output -raw admin_password`
- 연결: `terraform output -raw linux_ssh_connection`

## 🛠️ 트러블슈팅

### 일반적인 문제

1. **환경 설정 오류**
   ```bash
   # 환경별 설정 파일 존재 확인
   ls environments/dev/terraform.tfvars
   ls environments/hmc/terraform.tfvars
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
   - 환경별 접두사 확인 (`ict-dev-`, `ict-hmc-`, `ict-poc-`)

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

### 로그 확인

```bash
# 상세 로그로 문제 진단
export TF_LOG=DEBUG
terraform apply -var-file=environments/dev/terraform.tfvars
```

## 💰 비용 최적화

### 환경별 비용 관리

- **개발**: 작은 VM 크기, 필요시에만 실행
- **HMC**: 개발과 프로덕션 중간 크기
- **POC**: Proof of Concept 검증용 구성

### 비용 절약 팁

```bash
# 개발 환경 리소스 삭제 (비용 절약)
terraform workspace select dev
terraform destroy -var-file=environments/dev/terraform.tfvars

# HMC 환경 리소스 삭제 (테스트 완료 후)
terraform workspace select hmc
terraform destroy -var-file=environments/hmc/terraform.tfvars

# 자동 승인으로 삭제 (주의!)
terraform workspace select dev
terraform destroy -var-file=environments/dev/terraform.tfvars -auto-approve
```

## 📚 추가 리소스

- [Terraform Azure Provider 문서](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure VM 크기 가이드](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes)
- [Azure 네트워킹 모범 사례](https://docs.microsoft.com/en-us/azure/architecture/best-practices/network)

## 🤝 기여하기

1. 새로운 환경 추가 (예: `test`)
2. 환경별 설정 최적화
3. 배포 스크립트 개선
4. 문서 업데이트

---

**⚠️ 주의사항**: 프로덕션 환경 배포/삭제 시 신중하게 진행하세요. 실제 비즈니스에 영향을 줄 수 있습니다.