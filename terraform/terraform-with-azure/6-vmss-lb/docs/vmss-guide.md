# Azure VMSS (Virtual Machine Scale Set) 완벽 가이드

## 📖 개요

VMSS는 자동으로 확장/축소되는 VM 그룹입니다. 트래픽이 많아지면 자동으로 VM을 추가하고, 적어지면 제거합니다.

---

## 🎯 VMSS란?

### 문제: 수동으로 VM 관리하기

```
❌ 수동 관리 (불편)
  트래픽 폭증! → 관리자 호출 → VM 수동 추가
  (30분 소요)
  ↓
  서비스 중단 위험
```

### 해결책: VMSS로 자동화하기

```
✅ 자동 확장 (편함)
  트래픽 폭증! → VMSS 자동 감지 → VM 자동 추가
  (3초 소요)
  ↓
  사용자 영향 없음
```

### VMSS의 정의

```
VMSS = 동일한 설정의 VM들을 하나의 그룹으로 관리
      + 자동 확장/축소 규칙 적용
      + Load Balancer와 함께 사용
```

---

## 🏗️ VMSS의 핵심 구성 요소

```
┌─────────────────────────────────────────────┐
│      Azure VMSS (Virtual Machine           │
│      Scale Set)                             │
├─────────────────────────────────────────────┤
│                                             │
│  1️⃣ VM Instance 템플릿                      │
│     (모든 VM이 동일하게 생성될 기준)        │
│     - OS 이미지 (Ubuntu 22.04 LTS)        │
│     - VM 크기 (Standard_B1s)              │
│     - 저장소 설정                          │
│     - 네트워크 설정                        │
│                                             │
│  2️⃣ 용량 설정                               │
│     - 초기 인스턴스 수: 2개                │
│     - 최소 인스턴스 수: 2개                │
│     - 최대 인스턴스 수: 5개                │
│                                             │
│  3️⃣ 자동 확장 규칙                          │
│     - CPU 70% 이상 → 1개 추가             │
│     - CPU 30% 이하 → 1개 제거             │
│                                             │
│  4️⃣ Load Balancer 연동                      │
│     - Backend Pool에 자동 등록             │
│     - 트래픽 자동 분산                     │
│                                             │
└─────────────────────────────────────────────┘
```

---

## 💻 코드로 보는 VMSS 구조

### 1️⃣ VMSS 리소스 정의

```hcl
resource "azurerm_linux_virtual_machine_scale_set" "this" {
  name                = "web-vmss"
  resource_group_name = var.resource_group_name
  location            = var.location

  # VM 크기
  sku                 = "Standard_B1s"    # 작은 개발용 VM

  # 초기 인스턴스 수
  instances           = 2

  # 로그인 설정
  admin_username      = "azureuser"
  disable_password_authentication = false
  admin_password      = "Password1234!"   # ⚠️ 프로덕션에서는 SSH 키 사용
}
```

### 2️⃣ OS 이미지 지정

```hcl
source_image_reference {
  publisher = "Canonical"
  offer     = "0001-com-ubuntu-server-jammy"
  sku       = "22_04-lts"  # Ubuntu 22.04 LTS
  version   = "latest"      # 최신 버전
}
```

**의미**: 모든 VM을 Ubuntu 22.04 LTS로 생성한다

### 3️⃣ 저장소 설정

```hcl
os_disk {
  storage_account_type = "Standard_LRS"  # 표준 저장소
  caching              = "ReadWrite"     # 읽기/쓰기 캐싱
}
```

**의미**: 비용 효율적인 저장소 설정

### 4️⃣ 네트워크 설정

```hcl
network_interface {
  name    = "vmss-nic"
  primary = true

  ip_configuration {
    name                                   = "internal"
    primary                                = true
    subnet_id                              = var.subnet_id
    load_balancer_backend_address_pool_ids = [var.backend_pool_id]
  }
}
```

**의미**:
- `subnet_id`: VMSS의 VM들이 web-subnet에 배치
- `backend_pool_id`: 생성된 VM들이 Load Balancer의 backend-pool에 자동 등록

---

## 🔄 VMSS 동작 흐름

### 시간 흐름도

```
t=0분: VMSS 생성 시작
  ├─ instances = 2 설정
  └─ VM 2개 자동 생성
      ├─ web-vmss_1 (10.10.1.5)
      └─ web-vmss_2 (10.10.1.6)

t=5분: Load Balancer와 자동 연결
  └─ backend-pool에 2개 VM 등록 완료

t=15분: 모니터링 시작
  └─ 매 1분마다 CPU 사용률 확인

t=20분: 트래픽 증가 (CPU 75%)
  ├─ 자동 확장 규칙 발동 (CPU > 70%)
  ├─ VM 1개 추가 결정
  ├─ 5분 대기 (cooldown)
  └─ web-vmss_3 생성 (3개 VM으로 확장)

t=45분: 트래픽 감소 (CPU 25%)
  ├─ 자동 축소 규칙 발동 (CPU < 30%)
  ├─ VM 1개 제거 결정
  ├─ 5분 대기 (cooldown)
  └─ web-vmss_3 삭제 (2개 VM으로 축소)
```

### 시각적 흐름

```
사용자 요청 증가 (트래픽 ↑)
    ↓
Load Balancer가 분산
    ↓
각 VM의 CPU 사용률 상승
    ↓
Auto Scaling Monitor 감지 (CPU 70% 이상)
    ↓
✅ 스케일 업 규칙 실행
    ├─ 새 VM 생성
    ├─ 초기화 (custom_data 실행)
    └─ backend-pool에 자동 등록
    ↓
부하 분산 개선
```

---

## 🎛️ 우리 프로젝트의 VMSS 설정 상세

### VM 스펙

| 항목 | 값 | 의미 |
|------|-----|------|
| **SKU** | Standard_B1s | 1 vCPU, 1GB RAM (개발/테스트용) |
| **OS** | Ubuntu 22.04 LTS | 장기 지원 버전 |
| **초기 인스턴스** | 2 | 최소 요청 처리 가능 |
| **최대 인스턴스** | 5 | 비용 제어 |
| **저장소** | Standard_LRS | 비용 효율적 |

### Autoscaling 규칙

| 규칙 | 조건 | 동작 | Cooldown |
|------|------|------|----------|
| **Scale Up** | CPU > 70% | VM +1 추가 | 5분 |
| **Scale Down** | CPU < 30% | VM -1 제거 | 5분 |

### 네트워크 설정

```
VMSS
├─ 배치 위치: web-subnet (10.10.1.0/24)
├─ Private IP: 10.10.1.5 ~ 10.10.1.7 (동적 할당)
└─ Load Balancer 연동: backend-pool에 자동 등록
```

---

## 🔗 Load Balancer와의 연결

### 연결 메커니즘

```hcl
# VMSS 모듈 호출
module "vmss" {
  source = "../../modules/vmss"

  resource_group_name = module.network.resource_group_name
  location            = "Korea Central"
  subnet_id           = module.network.web_subnet_id
  backend_pool_id     = module.loadbalancer.backend_pool_id  # ← 연결!
}
```

### 데이터 흐름

```
Load Balancer (공개 IP: 20.30.40.50)
    ↓
backend-pool
    ├─ web-vmss_1 (10.10.1.5:80)
    ├─ web-vmss_2 (10.10.1.6:80)
    └─ web-vmss_3 (10.10.1.7:80) ← 자동 확장 시 추가됨

사용자 요청:
  http://20.30.40.50/
    ↓ (트래픽 분산)
  web-vmss_1, web-vmss_2, web-vmss_3 중 하나로 전달
```

---

## 📊 VMSS의 라이프사이클

### 1️⃣ 생성 (Creation)

```
terraform apply
    ↓
VMSS 리소스 생성
    ↓
instances = 2 설정으로 VM 2개 자동 생성
    ├─ web-vmss_1 (ID: 0)
    └─ web-vmss_2 (ID: 1)
    ↓
backend-pool에 자동 등록
    ↓
custom_data 실행 (Nginx 설치 등)
```

### 2️⃣ 모니터링 (Monitoring)

```
매 1분마다 메트릭 수집:
  ├─ CPU 사용률
  ├─ 메모리 사용률
  ├─ 네트워크 트래픽
  └─ ...
    ↓
5분 평균 계산
    ↓
규칙과 비교
```

### 3️⃣ 자동 확장 (Auto Scaling)

```
CPU 평균 > 70% (5분 동안)
    ↓
✅ Scale Up 규칙 발동
    ├─ 새 VM 생성 (web-vmss_3)
    ├─ 동일한 이미지/설정 적용
    ├─ custom_data 자동 실행
    └─ backend-pool에 자동 등록
    ↓
cooldown 기간 (5분)
    ├─ 이 동안 자동 확장/축소 안 함
    └─ 새로운 VM이 안정화될 시간 제공
```

### 4️⃣ 자동 축소 (Auto Scaling Down)

```
CPU 평균 < 30% (5분 동안)
    ↓
✅ Scale Down 규칙 발동
    ├─ 최신 생성된 VM 제거 (web-vmss_3)
    ├─ 연결 드레이닝 (graceful shutdown)
    └─ backend-pool에서 제거
    ↓
cooldown 기간 (5분)
    └─ 안정화 대기
```

---

## ⚙️ Auto Scaling의 세부 설정

### Monitor Autoscale Setting

```hcl
resource "azurerm_monitor_autoscale_setting" "this" {
  name                = "vmss-autoscale"
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.this.id

  profile {
    capacity {
      default = 2   # 일반적 상태: 2개
      minimum = 2   # 최소: 2개
      maximum = 5   # 최대: 5개
    }

    # Scale Up 규칙
    rule { ... }

    # Scale Down 규칙
    rule { ... }
  }
}
```

### Scale Up 규칙 상세

```hcl
rule {
  metric_trigger {
    metric_name        = "Percentage CPU"     # 감시 지표
    time_grain         = "PT1M"               # 1분 단위로 수집
    time_window        = "PT5M"               # 5분 평균으로 계산
    statistic          = "Average"            # 평균값 사용
    operator           = "GreaterThan"        # ~보다 크면
    threshold          = 70                   # 70%
  }

  scale_action {
    direction = "Increase"                    # 증가
    type      = "ChangeCount"                 # 개수 변경
    value     = "1"                           # 1개 추가
    cooldown  = "PT5M"                        # 5분 대기
  }
}
```

**의미**:
```
1분마다 CPU 수집
  ↓
5분 평균 계산
  ↓
평균이 70% 이상?
  ├─ YES → VM 1개 추가, 5분 대기
  └─ NO → 계속 모니터링
```

### 왜 이런 설정일까?

| 설정 | 이유 |
|------|------|
| **time_grain: PT1M** | 너무 자주 변경하지 않기 위해 |
| **time_window: PT5M** | 단기 트래픽 변동에 민감하지 않기 위해 |
| **threshold: 70%** | 여유 있는 확장 (80%는 위험) |
| **cooldown: PT5M** | 새 VM 초기화 시간 + 안정화 시간 |

---

## 🚨 자주 하는 실수

### ❌ 실수 1: backend_pool_id를 모듈에 전달하지 않음

```hcl
# 나쁜 예
module "vmss" {
  source = "../../modules/vmss"
  subnet_id = module.network.web_subnet_id
  # backend_pool_id를 안 넣음 ← Load Balancer와 연결 안 됨!
}
```

**결과**: VMSS가 생성되었지만 Load Balancer가 VM들을 모름 → 트래픽 분산 안 됨

**해결**:
```hcl
module "vmss" {
  source = "../../modules/vmss"
  backend_pool_id = module.loadbalancer.backend_pool_id  # ← 추가!
}
```

### ❌ 실수 2: custom_data 오류로 인한 Health Probe 실패

```hcl
# 나쁜 예
custom_data = base64encode(<<EOF
#!/bin/bash
apt-get install nginx  # 오류 가능성 높음
EOF
)
```

**결과**: Nginx 설치 실패 → Health Probe 실패 → VM이 정상으로 인식 안 됨

**해결**: 우리 코드처럼 오류 처리 추가
```hcl
- [ bash, -lc, "apt-get install -y nginx >> /var/log/cc_bootstrap.log 2>&1 || true" ]
# || true: 실패해도 계속 진행
```

### ❌ 실수 3: Cooldown 시간이 너무 짧음

```hcl
cooldown = "PT1M"  # 1분 ← 새 VM이 준비되지 않았는데 또 확장할 수 있음
```

**문제**: 과도한 확장/축소 반복 → 비용 증가

**해결**:
```hcl
cooldown = "PT5M"  # 5분 ← 충분한 안정화 시간
```

---

## 📈 실제 예시: 트래픽 변화에 따른 VMSS 동작

### Scenario: 오후 트래픽 폭증

```
14:00 - 점심 시간 여유
  VM 개수: 2개
  CPU 사용률: 25%

14:15 - 트래픽 증가 시작
  CPU 사용률: 68% (아직 안 함)

14:18 - 본격 트래픽 폭증
  CPU 사용률: 72% (5분 평균)
  ✅ 확장 규칙 발동!

14:20 - VM 1개 추가
  VM 개수: 3개
  CPU 사용률: 48% (부하 분산)
  cooldown 5분 시작

14:22 - 계속 증가
  CPU 사용률: 75%
  cooldown 진행 중 (자동 확장 안 함)

14:25 - cooldown 종료, 다시 평가
  CPU 사용률: 73%
  ✅ 또 확장 규칙 발동!

14:27 - VM 1개 더 추가
  VM 개수: 4개
  CPU 사용률: 42%
  cooldown 5분 시작

14:45 - 트래픽 정상화
  CPU 사용률: 28% (5분 평균)
  ✅ 축소 규칙 발동!

14:50 - 최신 VM 1개 제거
  VM 개수: 3개
  CPU 사용률: 35%
  cooldown 5분 시작

15:00 - 트래픽 정상
  CPU 사용률: 22%
  ✅ 축소 규칙 발동!

15:05 - VM 1개 제거
  VM 개수: 2개 (초기 상태로 복귀)
  CPU 사용률: 25%
```

---

## 🔐 프로덕션 고려사항

### 현재 코드의 보안 문제

```hcl
# 현재: 비밀번호 평문
admin_password = "Password1234!"  # ⚠️ 위험!
```

### 프로덕션 개선안

1. **SSH 키 사용**
```hcl
disable_password_authentication = true
admin_ssh_key {
  username   = "azureuser"
  public_key = file("~/.ssh/id_rsa.pub")
}
```

2. **비밀번호를 환경변수로**
```hcl
admin_password = var.admin_password
# terraform.tfvars에 넣지 말고 환경변수로: TF_VAR_admin_password
```

3. **더 강력한 암호 정책**
```hcl
# 최소 12자, 대문자, 소문자, 숫자, 특수문자 포함
```

---

## ✅ 체크리스트

VMSS를 올바르게 설정했는지 확인하세요:

- [ ] VMSS가 올바른 서브넷에 배치되었는가?
- [ ] backend_pool_id가 Load Balancer와 연결되었는가?
- [ ] custom_data가 Nginx를 설치하고 시작하는가?
- [ ] Health Probe가 /로 HTTP GET을 보낼 때 200 응답하는가?
- [ ] Auto Scaling 규칙이 합리적인가? (70% 증가, 30% 감소)
- [ ] Cooldown 시간이 충분한가? (최소 5분)
- [ ] 최대 인스턴스 수가 비용 내에서 설정되었는가?

---

## 🔗 관련 문서 및 파일

- [modules-connection-guide.md](modules-connection-guide.md) - 모듈 간 의존성 (VMSS ↔ Load Balancer)
- [azure-autoscaling-guide.md](azure-autoscaling-guide.md) - 자동 확장 상세
- [custom-data-guide.md](custom-data-guide.md) - Cloud-init 설정
- [modules/vmss/main.tf](../../modules/vmss/main.tf) - VMSS 구현
- [modules/vmss/variables.tf](../../modules/vmss/variables.tf) - VMSS 입력값
- [environments/dev/main.tf](../../environments/dev/main.tf) - VMSS 호출
