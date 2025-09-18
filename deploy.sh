#!/bin/bash

# 환경별 Terraform 배포 스크립트
# 사용법: ./deploy.sh [dev|staging|prod] [plan|apply|destroy]

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 함수 정의
print_usage() {
    echo -e "${BLUE}사용법: $0 [환경] [명령]${NC}"
    echo -e "${YELLOW}환경:${NC} dev, staging, prod"
    echo -e "${YELLOW}명령:${NC} plan, apply, destroy, init, validate"
    echo ""
    echo -e "${GREEN}예시:${NC}"
    echo "  $0 dev plan      # dev 환경 plan 실행"
    echo "  $0 prod apply    # prod 환경 apply 실행"
    echo "  $0 staging destroy # staging 환경 destroy 실행"
}

check_environment() {
    local env=$1
    if [[ ! "$env" =~ ^(dev|staging|prod)$ ]]; then
        echo -e "${RED}오류: 잘못된 환경입니다. dev, staging, prod 중 하나를 선택하세요.${NC}"
        print_usage
        exit 1
    fi
}

check_command() {
    local cmd=$1
    if [[ ! "$cmd" =~ ^(plan|apply|destroy|init|validate)$ ]]; then
        echo -e "${RED}오류: 잘못된 명령입니다. plan, apply, destroy, init, validate 중 하나를 선택하세요.${NC}"
        print_usage
        exit 1
    fi
}

check_terraform_config() {
    local env=$1
    local config_file="environments/$env/terraform.tfvars"
    
    if [[ ! -f "$config_file" ]]; then
        echo -e "${RED}오류: $config_file 파일을 찾을 수 없습니다.${NC}"
        exit 1
    fi
}

# 메인 로직
if [[ $# -ne 2 ]]; then
    echo -e "${RED}오류: 인수가 부족합니다.${NC}"
    print_usage
    exit 1
fi

ENVIRONMENT=$1
COMMAND=$2

# 입력 검증
check_environment $ENVIRONMENT
check_command $COMMAND
check_terraform_config $ENVIRONMENT

# 환경 변수 설정
export TF_VAR_environment=$ENVIRONMENT
export TF_CLI_ARGS="-var-file=environments/$ENVIRONMENT/terraform.tfvars"

echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Terraform $COMMAND 실행 중...${NC}"
echo -e "${YELLOW}환경: $ENVIRONMENT${NC}"
echo -e "${BLUE}========================================${NC}"

# 명령 실행
case $COMMAND in
    "init")
        echo -e "${YELLOW}Terraform 초기화 중...${NC}"
        terraform init
        ;;
    "validate")
        echo -e "${YELLOW}Terraform 구문 검증 중...${NC}"
        terraform validate
        ;;
    "plan")
        echo -e "${YELLOW}Terraform Plan 실행 중...${NC}"
        terraform plan
        ;;
    "apply")
        echo -e "${YELLOW}Terraform Apply 실행 중...${NC}"
        echo -e "${RED}경고: 실제 리소스가 생성/수정됩니다!${NC}"
        read -p "계속하시겠습니까? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            terraform apply -auto-approve
            echo -e "${GREEN}배포가 완료되었습니다!${NC}"
        else
            echo -e "${YELLOW}배포가 취소되었습니다.${NC}"
        fi
        ;;
    "destroy")
        echo -e "${RED}Terraform Destroy 실행 중...${NC}"
        echo -e "${RED}경고: 모든 리소스가 삭제됩니다!${NC}"
        read -p "정말로 삭제하시겠습니까? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            terraform destroy -auto-approve
            echo -e "${GREEN}리소스가 삭제되었습니다!${NC}"
        else
            echo -e "${YELLOW}삭제가 취소되었습니다.${NC}"
        fi
        ;;
esac

echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}완료!${NC}"
echo -e "${BLUE}========================================${NC}"
