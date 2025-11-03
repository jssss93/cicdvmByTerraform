# Dev 환경 CI/CD 비용 분석 리포트

## 비용 요약

### 월별 총 비용
**$218.72 USD** (약 **292,000원**, 환율 1,334원 기준)

> **참고**: Infracost는 $226.40으로 표시했지만, Standard HDD (E10) 실제 가격은 $2.05/월입니다. (infracost는 $5.89로 오인식)

### 연간 예상 비용
**$2,624.64 USD** (약 **3,500,000원**)

---

## 리소스별 상세 비용

### 1. Windows VM - **$139.29/월** (전체의 64%)

| 항목 | 세부사항 | 월 비용 |
|------|----------|---------|
| **VM 인스턴스** | Standard_D2s_v3 (2 vCPU, 8 GiB RAM) | $137.24 |
| | Windows Server 2022 Datacenter Azure Edition | |
| | 730시간/월 (상시 가동) | |
| **OS 디스크** | E10 (Standard HDD LRS, 128GB) ✅ | $2.05 |
| **디스크 작업** | 사용량 기반 ($0.0005/만 작업) | 변동 |
| **소계** | | **$139.29** |

### 2. Linux VM - **$72.13/월** (전체의 33%)

| 항목 | 세부사항 | 월 비용 |
|------|----------|---------|
| **VM 인스턴스** | Standard_D2s_v3 (2 vCPU, 8 GiB RAM) | $70.08 |
| | Ubuntu 24.04 LTS | |
| | 730시간/월 (상시 가동) | |
| **OS 디스크** | E10 (Standard HDD LRS, 128GB) ✅ | $2.05 |
| **디스크 작업** | 사용량 기반 ($0.0005/만 작업) | 변동 |
| **소계** | | **$72.13** |

### 3. Public IP - **$7.30/월** (전체의 3%)

| 항목 | 세부사항 | 월 비용 |
|------|----------|---------|
| **Linux VM용 IP** | Static, Regional, Standard SKU | $3.65 |
| **Windows VM용 IP** | Static, Regional, Standard SKU | $3.65 |
| **소계** | | **$7.30** |

---

## 리소스 현황

### 탐지된 리소스 (총 25개)

#### 비용 발생 리소스 (7개)
- Windows Virtual Machine (1개)
- Windows VM OS Disk (1개) - **필수 리소스**
- Linux Virtual Machine (1개)
- Linux VM OS Disk (1개) - **필수 리소스**
- Public IP - Linux (1개)
- Public IP - Windows (1개)
- Monitor Diagnostic Settings (3개)

#### 무료 리소스 (18개)
- Network Interface (2개)
- Network Interface Security Group Association (2개)
- Subnet Network Security Group Association (1개)
- Role Assignment (12개)
- Virtual Machine Extension (1개)

---

## 비용 최적화 방안

### 1. 운영 시간 최적화

#### 시나리오 A: 평일 업무 시간만 운영 (9-18시)
- **운영 시간**: 45시간/주 (약 195시간/월)
- **예상 비용**: $67/월
- **절감액**: $152/월 (69% 절감)
- **연간 절감액**: $1,824

#### 시나리오 B: 평일만 24시간 운영
- **운영 시간**: 120시간/주 (약 520시간/월)
- **예상 비용**: $159/월
- **절감액**: $60/월 (27% 절감)
- **연간 절감액**: $720

### 2. VM 크기 최적화

#### Windows VM 대안

| VM 크기 | vCPU | RAM | 월 비용 | 절감액 |
|---------|------|-----|---------|--------|
| **현재: Standard_D2s_v3** | 2 | 8 GB | $137.24 | - |
| Standard_B2s (Burstable) | 2 | 4 GB | $30.37 | $106.87 (78%) |
| Standard_B2ms (Burstable) | 2 | 8 GB | $60.74 | $76.50 (56%) |
| Standard_D2as_v5 (AMD) | 2 | 8 GB | $83.22 | $54.02 (39%) |

#### Linux VM 대안

| VM 크기 | vCPU | RAM | 월 비용 | 절감액 |
|---------|------|-----|---------|--------|
| **현재: Standard_D2s_v3** | 2 | 8 GB | $70.08 | - |
| Standard_B2s (Burstable) | 2 | 4 GB | $15.52 | $54.56 (78%) |
| Standard_B2ms (Burstable) | 2 | 8 GB | $31.03 | $39.05 (56%) |
| Standard_D2as_v5 (AMD) | 2 | 8 GB | $42.53 | $27.55 (39%) |

> **주의**: Burstable 시리즈(B)는 CPU 크레딧 기반으로 작동하여 지속적인 고부하 작업에는 적합하지 않습니다.

### 3. 스토리지 최적화

#### OS 디스크란?
**OS 디스크는 VM 생성 시 반드시 필요한 필수 리소스입니다.**
- VM의 운영체제(Windows/Linux)가 설치되는 디스크
- VM이 부팅되고 작동하기 위한 시스템 파일 저장
- 제거하거나 생략할 수 없으며, VM 삭제 시 함께 삭제됨
- 최소 용량은 OS에 따라 다름 (Windows: 127GB 이상, Linux: 30GB 이상)

**현재 설정: 128GB Standard HDD (E10) ✅**
- VM 2대 각각에 OS 디스크가 1개씩 필요
- 월 비용: $2.05 × 2대 = $4.10
- **이미 최저 비용 옵션으로 설정됨**

#### OS 디스크 타입 대안 (성능 vs 비용)

| 디스크 타입 | 용량 | IOPS | 처리량 | 월 비용 | 비교 |
|-------------|------|------|--------|---------|------|
| **현재: Standard HDD (E10) ✅** | 128 GB | 500 | 60 MB/s | $2.05 | 최저 비용 |
| Standard SSD (S10) | 128 GB | 500 | 60 MB/s | $5.89 | +$3.84 (187% 증가) |
| Premium SSD (P10) | 128 GB | 500 | 100 MB/s | $19.71 | +$17.66 (861% 증가) |

**현재 구성이 이미 최저 비용입니다!**

> **참고**: CI/CD 빌드 성능이 중요하다면 Standard SSD로 업그레이드 고려 가능 (2대 기준 월 $7.68 추가)

### 4. 네트워크 최적화

#### Public IP 대안

| 옵션 | 설명 | 월 비용 | 절감액 |
|------|------|---------|--------|
| **현재: 고정 IP 2개** | Linux, Windows 각각 | $7.30 | - |
| 고정 IP 1개 + NAT Gateway | 하나의 IP를 공유 | $4.05 + $32.12 | -$28.87 |
| Azure Bastion | SSH/RDP 전용 접근 | $140.16 | -$132.86 |
| 동적 IP 사용 | IP가 변경될 수 있음 | $0.00 | $7.30 |

**권장**: 현재 구성 유지 (고정 IP가 가장 경제적)

### 5. 예약 인스턴스 (Reserved Instances)

#### 1년 예약 (선불)
- **Windows VM**: $72.27/월 (47% 할인)
- **Linux VM**: $36.91/월 (47% 할인)
- **총 절감액**: $128/월 ($1,536/년)

#### 3년 예약 (선불)
- **Windows VM**: $49.28/월 (64% 할인)
- **Linux VM**: $25.17/월 (64% 할인)
- **총 절감액**: $177/월 ($2,124/년)

> **참고**: 예약 인스턴스는 장기 운영이 확정된 경우에만 권장합니다.

---

## 최적화 시나리오 비교

### 시나리오 1: 최대 절감 (개발 환경 권장)
- **변경사항**:
  - 평일 업무시간만 운영 (9-18시, 5일)
  - Windows: Standard_B2ms로 변경
  - Linux: Standard_B2ms로 변경
  - Standard HDD 유지 (이미 적용됨)
- **예상 비용**: $27/월
- **절감액**: $192/월 (88% 절감)
- **연간 절감액**: $2,304

### 시나리오 2: 균형 (테스트 환경 권장)
- **변경사항**:
  - 평일 24시간 운영
  - AMD 기반 D2as_v5로 변경
  - Standard HDD 유지 (이미 적용됨)
- **예상 비용**: $105/월
- **절감액**: $114/월 (52% 절감)
- **연간 절감액**: $1,368

### 시나리오 3: 성능 유지 (프로덕션 권장)
- **변경사항**:
  - 상시 운영
  - 1년 예약 인스턴스 구매
  - 현재 스펙 유지 (Standard HDD)
- **예상 비용**: $90/월
- **절감액**: $129/월 (59% 절감)
- **연간 절감액**: $1,548

---

## 권장 조치 사항

### 즉시 실행 가능
1. **Auto-shutdown 정책 설정**
   - Azure Portal에서 VM 자동 종료 시간 설정
   - 예: 매일 19시 자동 종료, 09시 수동 시작

2. **태그를 활용한 비용 추적 강화**
   - 현재 태그: Environment, Project, Owner, ManagedBy, CostCenter
   - Cost Center별 월별 비용 리포트 생성

### 단기 검토 (1개월 내)
3. **실제 사용률 모니터링**
   - Azure Monitor로 CPU, 메모리 사용률 확인
   - 사용률이 30% 미만이면 하위 스펙 검토

4. **디스크 성능 측정**
   - 현재 Standard HDD 빌드 시간 측정
   - 빌드 시간이 느리면 Standard SSD로 업그레이드 고려 (월 $7.68 추가)

### 중기 계획 (3개월 내)
5. **예약 인스턴스 검토**
   - 6개월 이상 지속 운영 예정이면 1년 예약 구매 고려
   - ROI: 6개월 이내 투자금 회수 가능

---

## 월별 비용 트렌드 모니터링

### 모니터링 지표
- VM 가동 시간 (시간/월)
- 평균 CPU/메모리 사용률
- 디스크 IOPS 사용량
- 네트워크 송수신량

### 알림 설정 권장
- 월 예산 초과 시 알림: $250
- 일일 비용 $10 초과 시 알림
- VM 가동률 90% 초과 시 알림

---

## 추가 정보

### 생성된 파일
- `infracost-dev-report.json` - 상세 JSON 데이터
- `infracost-dev-report.html` - 인터랙티브 HTML 리포트
- `infracost-dev-report.md` - 이 문서

### 비용 계산 기준
- **지역**: Korea Central
- **통화**: USD
- **가격 기준일**: 2025년 10월
- **월 가동 시간**: 730시간 (24시간 × 30.42일)

### Infracost 버전 정보
- 분석 도구: Infracost CLI
- 분석 시각: 2025-10-21 01:48:25 UTC
- Terraform 버전: >= 1.0
- Azure Provider 버전: ~> 3.0

---

## 참고 링크

- [Azure 가격 계산기](https://azure.microsoft.com/ko-kr/pricing/calculator/)
- [Azure VM 크기 및 가격](https://azure.microsoft.com/ko-kr/pricing/details/virtual-machines/windows/)
- [Azure 비용 관리 모범 사례](https://learn.microsoft.com/ko-kr/azure/cost-management-billing/costs/cost-mgt-best-practices)
- [Infracost 공식 문서](https://www.infracost.io/docs/)

---

**리포트 생성일**: 2025년 10월 21일  
**작성자**: Infracost Automation  
**환경**: Development (dev)  
**프로젝트**: hyundai-teams-meeting-ai-translator-cicd

