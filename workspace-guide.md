# Terraform Workspace를 사용한 환경별 State 분리

## 🎯 문제점
현재 구조에서는 모든 환경이 같은 state 파일을 공유하여 리소스 충돌이 발생할 수 있습니다.

## 💡 해결책: Terraform Workspace

### 1. Workspace 생성 및 전환

```bash
# 현재 workspace 확인
terraform workspace show

# 환경별 workspace 생성
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# workspace 전환
terraform workspace select dev      # 개발 환경
terraform workspace select staging  # 스테이징 환경
terraform workspace select prod     # 프로덕션 환경
```

### 2. 환경별 배포 (Workspace 사용)

```bash
# 개발 환경 배포
terraform workspace select dev
terraform init
terraform plan -var-file=environments/dev/terraform.tfvars
terraform apply -var-file=environments/dev/terraform.tfvars

# 스테이징 환경 배포
terraform workspace select staging
terraform plan -var-file=environments/staging/terraform.tfvars
terraform apply -var-file=environments/staging/terraform.tfvars

# 프로덕션 환경 배포
terraform workspace select prod
terraform plan -var-file=environments/prod/terraform.tfvars
terraform apply -var-file=environments/prod/terraform.tfvars
```

### 3. 환경별 상태 확인

```bash
# 현재 환경 확인
terraform workspace show

# 환경별 리소스 확인
terraform workspace select dev
terraform show

terraform workspace select staging
terraform show

terraform workspace select prod
terraform show
```

### 4. 환경별 리소스 삭제

```bash
# 개발 환경 삭제
terraform workspace select dev
terraform destroy -var-file=environments/dev/terraform.tfvars

# 스테이징 환경 삭제
terraform workspace select staging
terraform destroy -var-file=environments/staging/terraform.tfvars

# 프로덕션 환경 삭제
terraform workspace select prod
terraform destroy -var-file=environments/prod/terraform.tfvars
```

## 🔍 Workspace 관리 명령어

```bash
# 모든 workspace 목록 확인
terraform workspace list

# workspace 삭제 (주의: 해당 workspace의 리소스가 모두 삭제된 후)
terraform workspace delete <workspace-name>

# workspace 이름 변경 (직접 불가능, 새로 생성 후 이전)
```

## ⚠️ 주의사항

1. **Workspace 전환 필수**: 각 환경 배포 전에 반드시 해당 workspace로 전환
2. **리소스 이름 충돌**: 같은 workspace 내에서만 리소스 이름이 고유해야 함
3. **State 파일 위치**: 각 workspace는 별도의 state 파일을 가짐
   - `terraform.tfstate.d/dev/terraform.tfstate`
   - `terraform.tfstate.d/staging/terraform.tfstate`
   - `terraform.tfstate.d/prod/terraform.tfstate`
