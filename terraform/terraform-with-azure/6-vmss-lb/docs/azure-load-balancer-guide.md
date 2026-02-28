# Azure Load Balancer 완벽 가이드

## 📖 개요

Azure Load Balancer는 여러 서버로 들어오는 트래픽을 분산시키는 서비스입니다. 이 문서에서는 Load Balancer의 개념부터 우리 프로젝트의 구현까지 모두 설명합니다.

---

## 🎯 핵심 개념

### Load Balancer란?

**문제**: 하나의 서버로 모든 트래픽을 받으면 과부하가 발생합니다.

```
❌ 부하 분산 없음 (위험)
  모든 트래픽 → [서버 1] (과부하!)
              ↓
            서비스 다운
```

**해결책**: 여러 서버에 트래픽을 분산시킵니다.

```
✅ 부하 분산 (건강)
  트래픽 → [Load Balancer] → 서버 1 (30%)
                          → 서버 2 (30%)
                          → 서버 3 (40%)
```

### Azure Load Balancer의 역할

```
인터넷
  ↓
┌──────────────────────┐
│  Azure Load Balancer │
│  (공개 IP: 1.2.3.4)  │
└──────────────────────┘
  ↓
┌─────────────────────────────────┐
│  백엔드 서버들 (프라이빗 IP)     │
├─────────────────────────────────┤
│ 서버1: 10.10.1.5               │
│ 서버2: 10.10.1.6               │
│ 서버3: 10.10.1.7               │
└─────────────────────────────────┘
```

---

## 🏗️ Azure Load Balancer의 구조

### 4가지 핵심 구성요소

```
┌─────────────────────────────────────────┐
│      Azure Load Balancer                │
├─────────────────────────────────────────┤
│                                         │
│  1️⃣ Frontend IP Configuration           │
│     (공개 IP: 사용자 접근 포인트)        │
│     예: 1.2.3.4:80                      │
│                                         │
│  2️⃣ Backend Address Pool                │
│     (백엔드 서버 목록)                   │
│     예: 서버1, 서버2, 서버3              │
│                                         │
│  3️⃣ Load Balancing Rules                │
│     (어떻게 분산할지 규칙)              │
│     예: 포트 80 요청 → 백엔드로 전달     │
│                                         │
│  4️⃣ Health Probe                        │
│     (서버 상태 확인)                     │
│     예: 주기적으로 HTTP 요청 보내기     │
│                                         │
└─────────────────────────────────────────┘
```

### 각 구성요소의 상세 설명

#### 1️⃣ Frontend IP Configuration (프론트엔드)

**역할**: 사용자가 접근하는 "진입점"

```hcl
# Azure에서 공개 IP 생성
resource "azurerm_public_ip" "this" {
  name                = "lb-public-ip"
  allocation_method   = "Static"  # 항상 같은 IP
  sku                 = "Standard"
}

# Load Balancer 생성
resource "azurerm_lb" "this" {
  name = "web-lb"

  # 프론트엔드 설정
  frontend_ip_configuration {
    name                 = "public-frontend"
    public_ip_address_id = azurerm_public_ip.this.id
  }
}
```

**의미**:
- 사용자가 접속할 주소: `1.2.3.4` (공개 IP)
- 이 주소로 들어오는 모든 요청을 받음

#### 2️⃣ Backend Address Pool (백엔드)

**역할**: 실제 요청을 처리할 서버들의 목록

```hcl
resource "azurerm_lb_backend_address_pool" "this" {
  name            = "backend-pool"
  loadbalancer_id = azurerm_lb.this.id
}
```

**의미**:
- "backend-pool"이라는 이름의 서버 그룹을 생성
- 이후 VM이나 VMSS가 이 풀에 등록됨
- Load Balancer가 이 풀의 서버들에게 요청을 분산

**나중에 이 풀에 추가될 것들**:
```
backend-pool
├── VM1 (프라이빗 IP: 10.10.1.5)
├── VM2 (프라이빗 IP: 10.10.1.6)
└── VM3 (프라이빗 IP: 10.10.1.7)
```

#### 3️⃣ Load Balancing Rule (규칙)

**역할**: "어떤 트래픽을 어느 백엔드로 전달할지" 정의

```hcl
resource "azurerm_lb_rule" "http" {
  name                           = "http-rule"
  loadbalancer_id                = azurerm_lb.this.id

  # 프론트엔드 설정: 어느 포트로 들어오는 요청?
  protocol                       = "Tcp"
  frontend_port                  = 80      # 사용자가 접속: 1.2.3.4:80
  frontend_ip_configuration_name = "public-frontend"

  # 백엔드 설정: 어디로 전달?
  backend_port                   = 80      # 내부 서버의 80번 포트
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.this.id]

  # 헬스 체크 설정
  probe_id                       = azurerm_lb_probe.http.id
}
```

**의미**:
```
사용자 요청:
  1.2.3.4:80 (공개 IP, 포트 80)
  ↓
Load Balancer:
  "아, 포트 80이네. backend-pool의 서버 중 하나로 보내자"
  ↓
백엔드 서버:
  10.10.1.5:80 또는 10.10.1.6:80 또는 10.10.1.7:80
```

#### 4️⃣ Health Probe (헬스 체크)

**역할**: "어느 서버가 정상 상태인지" 확인

```hcl
resource "azurerm_lb_probe" "http" {
  name            = "http-probe"
  loadbalancer_id = azurerm_lb.this.id

  protocol     = "Http"         # HTTP로 확인
  port         = 80             # 80번 포트
  request_path = "/"            # 루트 경로 요청
}
```

**동작 방식**:
```
1초마다:
  Load Balancer → [서버 1] GET / → 응답 200 OK → ✅ 정상
                  [서버 2] GET / → 응답 200 OK → ✅ 정상
                  [서버 3] GET / → 응답 없음 → ❌ 다운됨

결과:
  트래픽 분산 대상 = 서버 1, 2만
  (서버 3은 복구될 때까지 제외)
```

**중요**: 헬스 체크에 응답하는 경로가 있어야 합니다!
```
예: 웹 서버가 GET / 요청에 200 OK를 반환해야 함
```

---

## 🔄 전체 흐름도

```
┌─────────────┐
│   사용자    │
└──────┬──────┘
       │ "1.2.3.4:80으로 접속"
       ↓
┌─────────────────────────────────────────┐
│    Frontend IP Configuration            │
│    (공개 IP: 1.2.3.4)                   │
│    포트 80번 요청 수신                   │
└──────┬──────────────────────────────────┘
       │
       │ "어느 서버로 보낼까?"
       │ (규칙: 포트 80 → backend-pool)
       ↓
┌─────────────────────────────────────────┐
│    Load Balancing Rule                  │
│    ✓ 헬스 체크 확인 (Health Probe)      │
│    ✓ 정상 서버 선택 (Round Robin)      │
└──────┬──────────────────────────────────┘
       │
       ├─→ 1번 요청: 서버 1 (10.10.1.5:80)
       │
       ├─→ 2번 요청: 서버 2 (10.10.1.6:80)
       │
       └─→ 3번 요청: 서버 3 (10.10.1.7:80)

           (또는 서버 3이 다운되면)

       ├─→ 1번 요청: 서버 1
       └─→ 2번 요청: 서버 2
```

---

## 💻 우리 프로젝트의 구현

### 현재 코드 분석

#### loadbalancer 모듈 (modules/loadbalancer/main.tf)

```hcl
# 1️⃣ 공개 IP 생성
resource "azurerm_public_ip" "this" {
  name                = "lb-public-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"      # 항상 같은 IP 유지
  sku                 = "Standard"    # 표준 SKU
}

# 2️⃣ Load Balancer 생성
resource "azurerm_lb" "this" {
  name                = "web-lb"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  # 프론트엔드 설정
  frontend_ip_configuration {
    name                 = "public-frontend"
    public_ip_address_id = azurerm_public_ip.this.id
  }
}

# 3️⃣ 백엔드 주소 풀
resource "azurerm_lb_backend_address_pool" "this" {
  name            = "backend-pool"
  loadbalancer_id = azurerm_lb.this.id
}

# 4️⃣ 헬스 체크
resource "azurerm_lb_probe" "http" {
  name            = "http-probe"
  loadbalancer_id = azurerm_lb.this.id
  protocol        = "Http"
  port            = 80
  request_path    = "/"
}

# 5️⃣ 로드 밸런싱 규칙
resource "azurerm_lb_rule" "http" {
  name                           = "http-rule"
  loadbalancer_id                = azurerm_lb.this.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "public-frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.this.id]
  probe_id                       = azurerm_lb_probe.http.id
}
```

#### 호출 (environments/dev/main.tf)

```hcl
module "loadbalancer" {
  source = "../../modules/loadbalancer"

  resource_group_name = module.network.resource_group_name
  location            = "Korea Central"
  backend_subnet_id   = module.network.web_subnet_id
}
```

---

## 🚀 다음 단계: VMSS와의 연결

현재 Load Balancer는 "준비 완료" 상태입니다. 다음을 추가하면 완전히 작동합니다:

### 1️⃣ VMSS (Virtual Machine Scale Set) 생성
```
VMSS = 자동으로 확장/축소되는 VM 그룹
예: 트래픽 많음 → VM 5개
    트래픽 적음 → VM 2개
```

### 2️⃣ VMSS를 Backend Pool에 등록
```
Load Balancer의 backend-pool에 VMSS의 VM들을 추가
```

### 3️⃣ NSG 규칙 설정
```
웹 서브넷의 NSG: 포트 80 인바운드 허용
(Load Balancer에서 오는 트래픽을 받을 수 있게)
```

---

## 🔐 Azure Load Balancer vs 온프레미스 로드 밸런서

| 항목 | Azure LB | 온프레미스 |
|------|---------|----------|
| **관리** | 관리형 (Azure) | 직접 관리 |
| **가용성** | 99.99% SLA | 하드웨어 의존 |
| **비용** | 사용량 기반 | 초기 투자 큼 |
| **확장성** | 즉시 확장 가능 | 물리 장비 구매 필요 |
| **설정** | 코드로 자동화 | 수동 설정 |

---

## 📊 트래픽 분산 알고리즘

### Default: Round Robin (라운드 로빈)

```
1번 요청 → 서버 1
2번 요청 → 서버 2
3번 요청 → 서버 3
4번 요청 → 서버 1
5번 요청 → 서버 2
...
```

### 다른 옵션들

- **Session Persistence**: 같은 사용자의 요청은 같은 서버로
- **Source IP Hash**: 클라이언트 IP 기반 분산
- **5-tuple hash**: 프로토콜, 출발지 IP, 출발지 포트, 목적지 IP, 목적지 포트 기반

---

## ⚠️ 자주 하는 실수

### ❌ 실수 1: Health Probe 응답 경로 없음

```hcl
resource "azurerm_lb_probe" "http" {
  port         = 80
  request_path = "/health"  # ← 이 경로가 없으면 계속 실패
}
```

**결과**: 모든 서버가 "다운됨"으로 표시 → 트래픽 안 전달됨

**해결**: 웹 서버에서 `/health` 경로가 200 응답하도록 설정

### ❌ 실수 2: NSG에서 포트 허용 안 함

```hcl
# NSG 규칙에서 80번 포트를 허용하지 않으면
# Load Balancer → 서버로의 트래픽이 차단됨
```

**해결**: NSG에서 포트 80 (또는 필요한 포트) 인바운드 허용

### ❌ 실수 3: Backend Pool에 서버 등록 안 함

```hcl
# backend-pool을 만들었지만
# VM을 추가하지 않으면 트래픽을 받을 곳이 없음
```

**해결**: VMSS 생성 후 backend-pool과 연결

---

## 🧪 테스트하기

### 1️⃣ Load Balancer 생성 후 IP 확인

```bash
# Terraform 적용
terraform apply

# 출력에서 Load Balancer의 공개 IP 확인
# 예: 20.30.40.50
```

### 2️⃣ 웹 서버 준비 (이후 단계)

```bash
# VMSS의 각 VM에 웹 서버 설치
# /health 경로 응답 설정
```

### 3️⃣ 트래픽 분산 확인

```bash
# 여러 번 접속하여 다른 서버에 도달하는지 확인
for i in {1..10}; do
  curl http://20.30.40.50/
done

# 응답에서 서버 ID를 확인하여 서로 다른지 검증
```

---

## 📚 Learn by Doing

### 실습 1: Backend Pool의 역할 이해

**목표**: Backend Pool 없이 Load Balancer를 만들면 어떻게 되는가?

```hcl
# backend-pool 주석 처리
# resource "azurerm_lb_backend_address_pool" "this" { ... }

# 이후 규칙 적용
# → 오류 발생: backend_address_pool_ids가 비어있음
```

**학습**: Backend Pool은 선택사항이 아닌 필수 구성요소

### 실습 2: Health Probe 응답 확인

**목표**: 헬스 체크 경로를 변경하면 어떻게 되는가?

```hcl
resource "azurerm_lb_probe" "http" {
  request_path = "/api/health"  # 이 경로가 없으면?
  # → 모든 서버가 "Unhealthy" 상태
}
```

**학습**: Health Probe는 실제로 존재하는 경로여야 함

---

## 🔗 관련 파일
- [modules/loadbalancer/main.tf](../../../modules/loadbalancer/main.tf) - Load Balancer 구현
- [modules/loadbalancer/variables.tf](../../../modules/loadbalancer/variables.tf) - 입력값
- [environments/dev/main.tf](../../../environments/dev/main.tf) - Load Balancer 호출
