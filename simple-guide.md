# 간단한 로컬 Workspace 사용법

## 🎯 현재 권장 방식: 로컬 Workspace

Azure Backend 설정이 복잡하고 권한 문제가 있으므로, **로컬 workspace 방식**을 계속 사용하는 것을 권장합니다.

## 📋 사용법

### 1. Workspace 생성 및 전환

```bash
# 현재 workspace 확인
terraform workspace show

# 환경별 workspace 생성 (최초 1회)
terraform workspace new dev
terraform workspace new hmc  
terraform workspace new poc

# workspace 전환
terraform workspace select dev
```

### 2. 환경별 배포

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

### 3. 환경별 상태 확인

```bash
# 현재 환경 확인
terraform workspace show

# 모든 workspace 목록
terraform workspace list

# 환경별 리소스 확인
terraform workspace select dev
terraform state list
terraform output
```

## 🔍 State 파일 위치

```bash
# 로컬 workspace state 파일들
ls -la terraform.tfstate.d/
├── dev/terraform.tfstate
├── hmc/terraform.tfstate
└── poc/terraform.tfstate
```

## ⚠️ 주의사항

1. **Workspace 전환 필수**: 각 환경 작업 전에 반드시 workspace 전환
2. **백업 권장**: 중요한 state 파일은 백업해두기
3. **개인/소규모 팀**: 로컬 방식이 더 간단하고 효율적

## 🚀 장점

- ✅ 설정이 간단함
- ✅ 빠른 실행 속도
- ✅ 외부 의존성 없음
- ✅ 비용 없음

## 📝 요약

현재 프로젝트에서는 **로컬 workspace 방식**을 계속 사용하세요:

```bash
terraform workspace select dev
terraform apply -var-file=environments/dev/terraform.tfvars
```

이 방식이 현재 상황에 가장 적합합니다!
