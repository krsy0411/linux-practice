# Azure Auto Scaling 완벽 가이드

## 📖 개요

Auto Scaling은 시스템의 부하에 따라 자동으로 리소스를 증가/감소시키는 기능입니다. 이 문서는 Azure Monitor를 통한 VMSS 자동 확장을 상세히 설명합니다.

---

## 🎯 Auto Scaling이란?

### 문제: 트래픽 변화 예측 불가

```
❌ 수동 관리 (위험)
  - 피크 시간에 모든 리소스 할당 → 대부분 낭비
  - 또는 최소 리소스만 할당 → 피크 시간에 다운
```

### 해결책: Auto Scaling

```
✅ 자동 조정 (효율적)
  - 필요한 만큼만 할당
  - 비용 절감
  - 안정성 향상
```

### 작동 원리

```
1. 메트릭 수집 (CPU, 메모리, 네트워크 등)
   ↓
2. 규칙 평가 (임계값과 비교)
   ↓
3. 동작 결정 (확장 또는 축소)
   ↓
4. 리소스 변경 (VM 추가/제거)
   ↓
5. 안정화 대기 (cooldown)
   ↓
6. 다시 1로 돌아가서 반복
```

---

## 🏗️ Azure Auto Scaling의 구조

### 5가지 핵심 개념

```
┌──────────────────────────────────────────────┐
│   Azure Monitor Autoscale Setting            │
├──────────────────────────────────────────────┤
│                                              │
│  1️⃣ Target Resource                         │
│     (자동 확장할 대상)                       │
│     예: VMSS "web-vmss"                     │
│                                              │
│  2️⃣ Profile                                 │
│     (확장 규칙 모음)                         │
│                                              │
│     ├─ Capacity (용량 설정)                  │
│     │  ├─ minimum: 최소 2개                 │
│     │  ├─ default: 일반 2개                 │
│     │  └─ maximum: 최대 5개                 │
│     │                                        │
│     └─ Rules (확장 규칙들)                   │
│        ├─ Rule 1: Scale Up                 │
│        │  (CPU > 70% → +1 VM)              │
│        │                                    │
│        └─ Rule 2: Scale Down               │
│           (CPU < 30% → -1 VM)              │
│                                              │
│  3️⃣ Metric Trigger                          │
│     (어떤 지표를 감시할지)                   │
│     - Percentage CPU                       │
│     - 메모리 사용률                         │
│     - 디스크 I/O                           │
│     - 네트워크 처리량                       │
│                                              │
│  4️⃣ Time Settings                           │
│     (시간 관련 설정)                         │
│     - time_grain: 수집 간격                 │
│     - time_window: 평가 기간                │
│     - cooldown: 대기 시간                   │
│                                              │
│  5️⃣ Scale Action                            │
│     (실행할 동작)                           │
│     - direction: 증가/감소                  │
│     - type: 변경 방식                       │
│     - value: 몇 개 변경                     │
│                                              │
└──────────────────────────────────────────────┘
```

---

## 📊 우리 프로젝트의 Auto Scaling 설정

### Autoscale Setting 전체 구조

```hcl
resource "azurerm_monitor_autoscale_setting" "this" {
  name                = "vmss-autoscale"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.this.id
  # ↑ 이 VMSS를 자동 확장 대상으로 지정

  profile {
    name = "default-profile"

    # 용량 설정
    capacity {
      default = 2
      minimum = 2
      maximum = 5
    }

    # Scale Up 규칙 (많은 부하)
    rule { ... }

    # Scale Down 규칙 (적은 부하)
    rule { ... }
  }
}
```

---

## 🔄 메트릭 수집 및 평가 과정

### Step-by-Step 흐름

```
├─ PT0M: 시작
│
├─ PT1M: 첫 번째 메트릭 수집
│  └─ CPU: [65%, 68%, 70%, 72%, 71%] (1초 단위)
│     (매 20초마다 수집, 총 5개)
│
├─ PT2M: 두 번째 메트릭 수집
│  └─ CPU: [71%, 73%, 72%, 74%, 75%]
│
├─ PT3M: 세 번째 메트릭 수집
│  └─ CPU: [74%, 75%, 76%, 77%, 75%]
│
├─ PT4M: 네 번째 메트릭 수집
│  └─ CPU: [75%, 76%, 77%, 76%, 74%]
│
├─ PT5M: 규칙 평가 시작! (time_window = PT5M)
│  │
│  ├─ 4분 동안 수집된 20개 샘플
│  │  └─ CPU: [65%, 68%, 70%, ..., 74%]
│  │
│  ├─ 평균 계산 (statistic = "Average")
│  │  └─ 평균 CPU: 72.5%
│  │
│  ├─ Scale Up 규칙 평가
│  │  └─ 72.5% > 70%? ✅ YES!
│  │
│  ├─ ✅ Scale Up 실행!
│  │  ├─ VM 개수: 2 → 3
│  │  └─ cooldown: PT5M 시작
│  │
│  └─ Scale Down 규칙 평가
│     └─ (Scale Up 실행되면 Down은 체크 안 함)
│
└─ PT10M: cooldown 종료, 다시 평가 가능
```

### 시간 설정의 의미

```hcl
metric_trigger {
  time_grain         = "PT1M"   # 1분 단위로 CPU 수집
  time_window        = "PT5M"   # 마지막 5분 데이터로 평가
  time_aggregation   = "Average" # 5분간의 평균값 사용
}
```

| 항목 | 값 | 의미 |
|------|-----|------|
| **time_grain** | PT1M | 매 1분마다 메트릭 수집 |
| **time_window** | PT5M | 지난 5분간의 평균으로 결정 |
| **time_aggregation** | Average | 최대/최소 아닌 평균값 사용 |

**왜 이렇게 설정?**
- PT1M: 자주 수집하면 노이즈 증가
- PT5M: 단기 변동에 덜 민감 (안정성 ↑)
- Average: 극단값에 영향받지 않음

---

## 🚀 Scale Up 규칙 상세 분석

### 코드로 보는 Scale Up

```hcl
rule {
  metric_trigger {
    metric_name        = "Percentage CPU"
    metric_resource_id = azurerm_linux_virtual_machine_scale_set.this.id
    time_grain         = "PT1M"       # 1분마다 수집
    statistic          = "Average"    # 평균값
    time_window        = "PT5M"       # 5분 데이터
    time_aggregation   = "Average"    # 평균 사용
    operator           = "GreaterThan"
    threshold          = 70           # 임계값 70%
  }

  scale_action {
    direction = "Increase"
    type      = "ChangeCount"
    value     = "1"                   # 1개 추가
    cooldown  = "PT5M"                # 5분 대기
  }
}
```

### 규칙 해석

```
IF (지난 5분간의 평균 CPU > 70%) THEN
  ├─ 현재 VM 개수 + 1
  └─ 다음 5분은 자동 확장/축소 안 함
```

### 예시: Scale Up 실행

```
현재 상태:
  - VM 개수: 2개
  - CPU: 68% (안전)

트래픽 증가:
  - 평균 CPU: 72% (5분 평균)

✅ Scale Up 조건 만족!
  1️⃣ VM 개수 증가: 2 → 3개
  2️⃣ 새 VM 초기화 (custom_data 실행)
  3️⃣ Nginx 설치 완료
  4️⃣ Load Balancer backend-pool에 등록
  5️⃣ 트래픽 분산 시작

결과:
  - CPU: 68% ÷ 3 = 약 48%
  - Cooldown: 5분 대기
```

---

## ⬇️ Scale Down 규칙 상세 분석

### 코드로 보는 Scale Down

```hcl
rule {
  metric_trigger {
    metric_name        = "Percentage CPU"
    time_grain         = "PT1M"
    statistic          = "Average"
    time_window        = "PT5M"
    time_aggregation   = "Average"
    operator           = "LessThan"    # 보다 작으면
    threshold          = 30            # 임계값 30%
  }

  scale_action {
    direction = "Decrease"
    type      = "ChangeCount"
    value     = "1"                    # 1개 제거
    cooldown  = "PT5M"
  }
}
```

### 규칙 해석

```
IF (지난 5분간의 평균 CPU < 30%) THEN
  ├─ 현재 VM 개수 - 1 (최소값 이상)
  └─ 다음 5분은 자동 확장/축소 안 함
```

### 예시: Scale Down 실행

```
현재 상태:
  - VM 개수: 3개
  - CPU: 28% (낮음)

트래픽 감소:
  - 평균 CPU: 25% (5분 평균)

✅ Scale Down 조건 만족!
  1️⃣ VM 제거 대상: 최신 생성된 VM (web-vmss_3)
  2️⃣ 연결 드레이닝 (진행 중인 요청 완료 대기)
  3️⃣ VM 정리 및 제거
  4️⃣ Load Balancer backend-pool에서 제거

결과:
  - VM 개수: 3 → 2개 (초기 상태)
  - CPU: 안정적 수준 유지
  - 비용 절감!
```

---

## ⏰ Cooldown 기간의 중요성

### Cooldown이란?

```
자동 확장/축소 후, 다음 규칙 평가를 할 때까지의 대기 시간
```

### Cooldown 설정의 영향

```
❌ Cooldown = PT1M (1분)
  시간 →
  t=0   : Scale Up 실행 (CPU 72%)
  t=1   : cooldown 종료
  t=1   : Scale Down 조건 평가?
          → 새 VM 아직 준비 중 (Nginx 설치 진행)
          → CPU 측정 불안정
  t=2   : 또 Scale Up? (데이터 불안정)
  t=3   : 또 Scale Down?

  결과: 계속 증감 반복 (ping-pong effect) 🚫

✅ Cooldown = PT5M (5분)
  시간 →
  t=0   : Scale Up 실행 (CPU 72%)
  t=1-5 : cooldown 진행 중
          - 새 VM 초기화 완료
          - 부하 분산 안정화
          - 메트릭 안정화
  t=5   : cooldown 종료
  t=5   : 다시 평가 (안정적 데이터)

  결과: 필요한 만큼만 확장 ✅
```

### Cooldown 시간 선택 기준

| Cooldown | 상황 | 비고 |
|----------|------|------|
| **PT1M** | ❌ 너무 짧음 | 새 VM 초기화 미완료 |
| **PT3M** | 별로 안 좋음 | 최소 상황 |
| **PT5M** | ✅ 추천 | 초기화 + 안정화 시간 |
| **PT10M** | 긴 대기 | 트래픽 변화가 느린 경우 |
| **PT30M** | ❌ 너무 길음 | 트래픽 급변 시 대응 어려움 |

---

## 📈 실제 트래픽 패턴별 Auto Scaling 시뮬레이션

### Scenario 1: 점진적 트래픽 증가

```
시간    트래픽  CPU   상태          동작
────────────────────────────────────────
10:00   낮음   25%   안정           -
10:05   낮음   28%   안정           -
10:10   중간   35%   안정           -
10:15   증가   45%   주의           -
10:20   많음   68%   주의           -
10:25   많음   72% ✅ Scale Up!     VM: 2→3
        (cooldown 시작)
10:30   많음   73%   cooldown 진행  -
10:35   많음   75%   cooldown 종료   -
        평가: 74% > 70% ✅ Scale Up! VM: 3→4
        (cooldown 시작)
10:40   많음   72%   cooldown 진행  -
10:45   많음   71%   cooldown 종료   -
        평가: 71% > 70% ✅ Scale Up! VM: 4→5 (최대)
        (cooldown 시작)
10:50   많음   69%   cooldown 진행  -
10:55   많음   65%   cooldown 종료   -
        평가: 65% < 70% but > 30%  -
11:00   감소   40%   안정           -
11:05   감소   28% ✅ Scale Down!   VM: 5→4
        (cooldown 시작)
11:10   낮음   22%   cooldown 진행  -
11:15   낮음   20%   cooldown 종료   -
        평가: 20% < 30% ✅ Scale Down! VM: 4→3
        (cooldown 시작)

결과: 부하에 따라 자동 조정 ✅
```

### Scenario 2: 급격한 트래픽 폭증 (장애 발생)

```
시간    트래픽  상태              VM   CPU
────────────────────────────────────────
14:00   정상   안정              2    25%
14:01   폭증!  느린 응답         2    85% ⚠️
        (규칙 평가 대기)
14:02   폭증!  매우 느림         2    88% ⚠️
14:03   폭증!  데이터 수집 완료  2    87%
14:04   폭증!  5분 평가 준비     2    86%
14:05   폭증!  ✅ Scale Up 조건  3    80%
        평균 CPU: 85% > 70%
        (cooldown 시작)
14:06   폭증!  cooldown 진행     3    78%
14:07   폭증!  cooldown 진행     3    76%
14:08   폭증!  cooldown 진행     3    72%
14:09   폭증!  cooldown 진행     3    71%
14:10   폭증!  cooldown 종료     3    75%
        ✅ Scale Up 다시 (avg: 74% > 70%)
14:11   폭증!  새 VM 추가        4    70%
        (cooldown 시작)

관찰:
- 5분 대기 → 사용자 영향 가능
- 그래서 모니터링 + 수동 대응 필요
```

---

## 🔍 메트릭 모니터링 (Azure Portal)

### 모니터링 위치

```
Azure Portal
  ↓
Virtual Machine Scale Sets
  ↓
web-vmss
  ↓
Scaling
  ↓
Autoscale settings
  ↓
vmss-autoscale (확인 가능)
```

### 확인할 항목

1. **Scaling History** (확장 이력)
   - 언제 확장/축소 되었는가?
   - 왜 실행되었는가? (규칙)

2. **Instance Count** (인스턴스 개수)
   - 현재 VM 개수
   - 최소/최대 범위

3. **Average CPU** (평균 CPU)
   - 5분 단위 평균값
   - 임계값(70%, 30%)과 비교

4. **Pending Operations** (대기 중인 동작)
   - 진행 중인 확장/축소

---

## 🚨 자주 하는 실수

### ❌ 실수 1: 임계값이 너무 높음

```hcl
threshold = 90  # ← 위험!
```

**문제**:
- 90% CPU 도달 = 이미 시스템 과부하
- 사용자 경험 이미 나빠짐
- 확장까지 시간 소요 = 더 악화

**해결**:
```hcl
threshold = 70  # ← 여유 있게 설정
```

### ❌ 실수 2: 임계값이 너무 낮음

```hcl
threshold = 20  # ← 비용 낭비
```

**문제**:
- 조금만 부하 증가해도 VM 추가
- 계속 확장/축소 반복
- 비용 증가

**해결**:
```hcl
threshold = 70  # ← 합리적 여유
```

### ❌ 실수 3: Scale Down 임계값 > Scale Up 임계값

```hcl
# Scale Up: 70%
# Scale Down: 80% ← 이상함!
```

**문제**:
```
70% 도달 → Scale Up (VM 추가)
  ↓ (부하 분산)
60% 로 떨어짐 → Scale Down 검토
80%? 아직 높음 → Down 안 함
→ 계속 3개 VM 유지
→ 비용 낭비
```

**해결**:
```hcl
# Scale Up: 70%
# Scale Down: 30% ← 충분한 간격
# 간격이 크면: 확장/축소 반복 방지
```

### ❌ 실수 4: 최대 VM 개수를 최소값과 같게

```hcl
capacity {
  minimum = 5
  maximum = 5  # ← 자동 확장 불가!
}
```

**문제**: Auto Scaling이 의미 없음

**해결**:
```hcl
capacity {
  minimum = 2
  maximum = 5  # ← 확장 여지 있음
}
```

---

## 📊 비용 최적화 팁

### 현재 설정의 비용

```
Standard_B1s VM 1개/시간: $0.048
(예시, 실제는 region에 따라 다름)

최소: 2개 × 24시간 = $2.30/일
최대: 5개 × 8시간 + 2개 × 16시간 = $2.59/일 (피크 시간 가정)

월 비용: 약 $70-80
```

### 최적화 방법

1. **적절한 VM 크기 선택**
   ```hcl
   sku = "Standard_B1s"  # 충분하면 더 작은 크기 고려
   ```

2. **합리적인 최대값**
   ```hcl
   maximum = 5  # 너무 크면 비용 폭증
   ```

3. **Reserved Instances 고려**
   - 최소값(2개)을 Reserved로 예약
   - 나머지는 On-Demand로

---

## ✅ Auto Scaling 검증 체크리스트

- [ ] Target Resource가 올바른가? (VMSS ID)
- [ ] Capacity가 합리적인가? (최소 < 기본 < 최대)
- [ ] Scale Up 규칙의 임계값이 합리적인가? (50-80% 범위)
- [ ] Scale Down 규칙의 임계값이 합리적인가? (20-40% 범위)
- [ ] Scale Down < Scale Up이 맞나?
- [ ] Cooldown이 충분한가? (최소 5분)
- [ ] Metric이 수집 가능한가? (VMSS가 켜져 있나?)
- [ ] Autoscale Setting이 "Enabled"인가?

---

## 🔗 관련 문서 및 파일

- [vmss-guide.md](vmss-guide.md) - VMSS 기본 개념
- [custom-data-guide.md](custom-data-guide.md) - VM 초기화
- [modules/vmss/main.tf](../../modules/vmss/main.tf) - Autoscale 구현
- [Azure Monitor 공식 문서](https://docs.microsoft.com/azure/azure-monitor/)
