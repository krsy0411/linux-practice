# 6-vmss-lb: Azure Load Balancer와 VMSS를 이용한 확장 가능한 인프라

## 📋 프로젝트 개요

이 프로젝트는 Azure에서 **Virtual Machine Scale Set (VMSS)**과 **Load Balancer**를 활용하여 자동으로 확장 가능한 웹 서버 인프라를 구성하는 실습입니다.

### 학습 목표
- ✅ Terraform 모듈 구조 및 재사용성 이해
- ✅ Azure 네트워크 아키텍처 구성 (VPC, 서브넷, NSG)
- ✅ Load Balancer를 통한 트래픽 분산
- ✅ VMSS (Virtual Machine Scale Set) 구성 및 Load Balancer 연결
- ✅ Auto Scaling 규칙 설정 및 모니터링
- ✅ Cloud-init을 통한 VM 자동 초기화
- ✅ Infrastructure as Code (IaC)의 실제 적용

---

## 📁 프로젝트 구조

```
6-vmss-lb/
├── README.md                    ← 현재 파일
├── docs/                        ← 학습 문서
│   ├── terraform-variables-guide.md      (Terraform 변수)
│   ├── modules-connection-guide.md       (모듈 연결 관계)
│   ├── azure-load-balancer-guide.md      (Load Balancer)
│   ├── vmss-guide.md                     (VMSS 개념)
│   ├── azure-autoscaling-guide.md        (자동 확장)
│   └── custom-data-guide.md              (VM 초기화)
│
├── modules/                     ← 재사용 가능한 모듈들
│   ├── network/                 (VPC, 서브넷, 리소스 그룹)
│   ├── nsg/                     (네트워크 보안 그룹)
│   ├── loadbalancer/            (로드 밸런서)
│   └── vmss/                    (VM 스케일 세트)
│
├── environments/dev/            ← 개발 환경 설정
│   ├── main.tf                  (모듈 호출)
│   ├── variables.tf             (환경 변수)
│   ├── terraform.tfvars         (실제 값 - .gitignore 처리)
│   └── backend.tf               (상태 파일 저장소)
│
└── bootstrap/                   ← 상태 파일 저장소 초기화
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

---

## 📚 학습 가이드

### Terraform 기초
| 주제 | 문서 | 내용 |
|------|------|------|
| **변수 개념** | [📖 terraform-variables-guide.md](docs/terraform-variables-guide.md) | `variables.tf` vs `terraform.tfvars`의 차이, 변수 우선순위, 모듈 내 변수 동작 |
| **모듈 설계** | [📖 modules-connection-guide.md](docs/modules-connection-guide.md) | 모듈 생성 방법, 모듈 간 의존성, 출력값(outputs) 활용, 데이터 흐름 |

### Azure 인프라
| 주제 | 문서 | 내용 |
|------|------|------|
| **로드 밸런서** | [📖 azure-load-balancer-guide.md](docs/azure-load-balancer-guide.md) | Load Balancer 구조, 프론트엔드/백엔드, Health Probe, 트래픽 분산 |
| **VMSS** | [📖 vmss-guide.md](docs/vmss-guide.md) | Virtual Machine Scale Set 개념, 구조, Load Balancer와의 연결 |

### 고급 기능
| 주제 | 문서 | 내용 |
|------|------|------|
| **자동 확장** | [📖 azure-autoscaling-guide.md](docs/azure-autoscaling-guide.md) | Auto Scaling 메커니즘, 메트릭 수집, 규칙 평가, cooldown |
| **VM 초기화** | [📖 custom-data-guide.md](docs/custom-data-guide.md) | Cloud-init, Custom Data, 패키지 설치, 파일 생성, 오류 처리 |

---

## 🚀 빠른 시작

### 1️⃣ 전제 조건

```bash
# 필수 도구 설치 확인
terraform version      # >= 1.5.0
az --version          # Azure CLI
```

### 2️⃣ Azure 인증

```bash
# Azure CLI로 로그인
az login

# 구독 선택
az account set --subscription "<subscription-id>"
```

### 3️⃣ Terraform 초기화

```bash
# 개발 환경으로 이동
cd environments/dev

# 상태 파일 저장소 설정 (처음 한 번만)
# bootstrap/ 폴더의 Terraform을 먼저 실행
cd ../../bootstrap
terraform init
terraform apply

# 개발 환경으로 돌아가서
cd ../environments/dev

# Terraform 초기화
terraform init
```

### 4️⃣ 인프라 생성

```bash
# 생성할 리소스 확인
terraform plan

# 인프라 생성
terraform apply

# 생성된 리소스 확인
terraform output
```

### 5️⃣ 정리

```bash
# 생성된 모든 리소스 삭제
terraform destroy
```

---

## 🏗️ 아키텍처 다이어그램

```
┌─────────────────────────────────────────────────────────────┐
│                      인터넷 (사용자)                          │
└──────────────────────┬──────────────────────────────────────┘
                       │ HTTP 요청
                       ↓
        ┌──────────────────────────────┐
        │    Azure Load Balancer       │
        │    (공개 IP: 20.30.40.50)   │
        │    - Frontend: 포트 80       │
        │    - Backend: backend-pool   │
        │    - Health Probe: /         │
        └──────┬───────────────────────┘
               │ 트래픽 분산
        ┌──────┴───────────────┐
        │                      │
        ↓                      ↓
  ┌────────────────┐    ┌────────────────┐
  │  VMSS: web-vmss│    │  (또는 더 많은 │
  │  - 최소 2개    │    │   VM으로 확장) │
  │  - 최대 5개    │    │                │
  │  - Auto Scale  │    │ Auto Scale에서 │
  │    규칙 적용   │    │   추가/제거    │
  └────────────────┘    └────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                     VPC: 10.10.0.0/16                       │
├──────────────────────┬──────────────────────────────────────┤
│ Web Subnet           │ DB Subnet                            │
│ 10.10.1.0/24         │ 10.10.2.0/24                         │
│                      │                                      │
│ VMSS VMs:           │ Reserved for                         │
│ 10.10.1.5~.7        │ Database layer                       │
│ (Nginx + Cloud-init) │ (미구현)                             │
│                      │                                      │
│ NSG Rules:           │ NSG Rules:                           │
│ ✓ 80: 인바운드       │ ✓ 3306: 인바운드 (프라이빗)        │
│ ✓ 443: 인바운드      │ ✓ 아웃바운드: 모두 허용            │
└──────────────────────┴──────────────────────────────────────┘
```