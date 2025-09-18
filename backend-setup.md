# Terraform Remote Backend 설정 가이드

## 🎯 문제점
현재 로컬 workspace 방식의 한계:
- 팀 협업 시 state 파일 공유 불가
- 로컬 머신 손실 시 state 파일 유실
- 동시 작업 시 충돌 가능성

## 💡 해결책: Azure Storage Backend

### 1. Azure Storage Account 생성

```bash
# 기존 리소스 그룹 사용 (권한이 있는 리소스 그룹)
# az group create --name rg-terraform-state --location "Korea Central"  # 권한 없음

# Storage Account 생성 (기존 리소스 그룹 사용)
az storage account create \
  --name stterraformstatecjs2 \
  --resource-group rg-az01-poc-hyundai.teams-01 \
  --location "Korea Central" \
  --sku Standard_LRS

# Container 생성
az storage container create \
  --name terraform-state \
  --account-name stterraformstatecjs2

# Storage Account에 대한 권한 추가 (관리자 권한 필요)
# 현재 사용자에게 Storage Account Contributor 역할 할당
az role assignment create \
  --assignee "jongsu.choi_kt.com#EXT#@ktopen.onmicrosoft.com" \
  --role "Storage Account Contributor" \
  --scope "/subscriptions/d69e62aa-ef39-4bc0-b745-57ebc2bddcc8/resourceGroups/rg-az01-poc-hyundai.teams-01/providers/Microsoft.Storage/storageAccounts/stterraformstatecjs2"

# 또는 Storage Blob Data Contributor 역할 할당 (더 세밀한 권한)
az role assignment create \
  --assignee "jongsu.choi_kt.com#EXT#@ktopen.onmicrosoft.com" \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/d69e62aa-ef39-4bc0-b745-57ebc2bddcc8/resourceGroups/rg-az01-poc-hyundai.teams-01/providers/Microsoft.Storage/storageAccounts/stterraformstatecjs2"

# 권한 확인
az role assignment list \
  --assignee "jongsu.choi_kt.com#EXT#@ktopen.onmicrosoft.com" \
  --scope "/subscriptions/d69e62aa-ef39-4bc0-b745-57ebc2bddcc8/resourceGroups/rg-az01-poc-hyundai.teams-01/providers/Microsoft.Storage/storageAccounts/stterraformstatecjs2" \
  --output table
```

### 2. Terraform Backend 설정

`main.tf`에 backend 설정 추가:

```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
  
  backend "azurerm" {
    resource_group_name  = "rg-az01-poc-hyundai.teams-01"
    storage_account_name = "stterraformstatecjs2"
    container_name       = "terraform-state"
    key                  = "terraform.tfstate"
  }
}
```

### 3. 환경별 Backend Key 설정

각 환경별로 다른 key를 사용:

```bash
# 개발 환경
terraform init \
  -backend-config="key=dev/terraform.tfstate"

# HMC 환경  
terraform init \
  -backend-config="key=hmc/terraform.tfstate"

# POC 환경
terraform init \
  -backend-config="key=poc/terraform.tfstate"
```

### 4. 환경별 배포 (Remote Backend)

```bash
# 개발 환경
terraform workspace select dev || terraform workspace new dev
terraform plan -var-file=environments/dev/terraform.tfvars
terraform apply -var-file=environments/dev/terraform.tfvars

# HMC 환경
terraform workspace select hmc || terraform workspace new hmc
terraform plan -var-file=environments/hmc/terraform.tfvars
terraform apply -var-file=environments/hmc/terraform.tfvars

# POC 환경
terraform workspace select poc || terraform workspace new poc
terraform plan -var-file=environments/poc/terraform.tfvars
terraform apply -var-file=environments/poc/terraform.tfvars
```

## 🔍 Backend vs Local 비교

| 구분 | 로컬 Workspace | Remote Backend |
|------|----------------|----------------|
| **설정** | 간단 | 복잡 |
| **협업** | 불가능 | 가능 |
| **안정성** | 낮음 (로컬 의존) | 높음 (Azure 저장) |
| **동시 작업** | 충돌 위험 | 안전 |
| **비용** | 무료 | Storage 비용 |
| **속도** | 빠름 | 약간 느림 |

## 🚀 권장 사항

### 개발/개인 프로젝트
- **로컬 workspace 사용** (현재 방식)
- 빠르고 간단한 설정

### 팀/프로덕션 프로젝트  
- **Azure Storage Backend 사용**
- 안정성과 협업 지원

## 📋 Backend 설정 단계

1. **Storage Account 생성**
2. **main.tf에 backend 블록 추가**
3. **terraform init으로 마이그레이션**
4. **환경별 key 설정**
5. **정상 작동 확인**

## ⚠️ 주의사항

- Backend 설정 변경 시 기존 state 파일 마이그레이션 필요
- Storage Account 이름은 전역적으로 고유해야 함
- 적절한 권한 설정 필요 (RBAC)
