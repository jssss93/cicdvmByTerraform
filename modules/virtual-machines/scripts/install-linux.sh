#!/bin/bash
# Linux VM 초기 설정 스크립트 (Bash)
# Azure CLI, Docker 및 개발 도구 설치
# VM 생성 시 자동 실행되는 스크립트

# 로그 파일 설정
LOG_FILE="/var/log/vm-setup.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# 로그 함수
log() {
    echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE"
}

log "Linux VM 초기 설정 시작"

# 시스템 업데이트
log "시스템 패키지 업데이트 중..."
apt-get update -y

# 필수 패키지 설치
log "필수 패키지 설치 중..."
apt-get install -y curl apt-transport-https lsb-release gnupg

# Microsoft GPG 키 추가
log "Microsoft GPG 키 추가 중..."
curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null

# Azure CLI 리포지토리 추가
log "Azure CLI 리포지토리 추가 중..."
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | tee /etc/apt/sources.list.d/azure-cli.list

# 패키지 목록 업데이트
log "패키지 목록 업데이트 중..."
apt-get update -y

# Azure CLI 설치
log "Azure CLI 설치 중..."
apt-get install -y azure-cli

# Azure CLI 버전 확인
log "Azure CLI 설치 확인 중..."
if command -v az &> /dev/null; then
    AZ_VERSION=$(az version --output tsv 2>/dev/null | head -n1)
    log "Azure CLI 설치 성공: $AZ_VERSION"
else
    log "Azure CLI 설치 실패"
fi

# 추가 도구 설치
log "추가 도구 설치 중..."
apt-get install -y git wget curl unzip jq

# Docker 설치 (선택적)
log "Docker 설치 중..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker $USER

# 시스템 서비스 활성화
log "시스템 서비스 설정 중..."
systemctl enable docker
systemctl start docker

# 사용자 정의 스크립트 실행
CUSTOM_SCRIPT="${custom_script}"
if [ ! -z "$CUSTOM_SCRIPT" ] && [ "$CUSTOM_SCRIPT" != "" ]; then
    log "사용자 정의 스크립트 실행 중..."
    eval "$CUSTOM_SCRIPT" 2>&1 | tee -a "$LOG_FILE"
    if [ $? -eq 0 ]; then
        log "사용자 정의 스크립트 실행 완료"
    else
        log "사용자 정의 스크립트 실행 오류"
    fi
fi

# 정리 작업
log "정리 작업 중..."
apt-get autoremove -y
apt-get autoclean

log "모든 설치 작업 완료"

# 설치 완료 마커 파일 생성
touch /tmp/vm-setup-complete

log "VM 초기 설정 스크립트 종료"
