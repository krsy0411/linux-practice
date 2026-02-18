# Azure 네트워크 기초 with Terraform

> **학습 목표**: Azure VNet과 Subnet의 개념을 이해하고, Terraform에서 리소스 간 의존성을 관리하는 방법을 학습합니다.

---

## 1. Azure 네트워크 기초 개념 🌐

### 1.1 Azure Virtual Network (VNet)란?

**VNet**은 Azure에서 제공하는 **논리적으로 격리된 네트워크 공간**입니다.

#### 🏢 현실 세계 비유
- **VNet** = 회사 건물 전체
- **Subnet** = 건물 내 각 층 또는 부서
- **리소스(VM 등)** = 각 층에 배치된 직원들

#### 핵심 특징

| 특징 | 설명 |
|------|------|
| **격리성** | 다른 VNet과 완전히 분리된 네트워크 공간 |
| **주소 공간** | CIDR 표기법으로 정의 (예: 10.0.0.0/16) |
| **Subnet 분할** | VNet을 여러 Subnet으로 나눠 관리 |
| **보안** | NSG(Network Security Group)로 트래픽 제어 |
| **연결성** | VPN, ExpressRoute, Peering으로 다른 네트워크와 연결 |

### 1.2 CIDR 표기법 이해하기

#### 📊 CIDR이란?
**CIDR**(Classless Inter-Domain Routing)은 IP 주소 범위를 표기하는 방법입니다.

```
10.0.0.0/16
│        │
│        └─ 서브넷 마스크 비트 수
└────────── 네트워크 주소
```

#### 비트수와 사용 가능한 IP 개수

| CIDR | 서브넷 마스크 | 사용 가능 IP 개수 | 용도 예시 |
|------|--------------|-----------------|----------|
| /8 | 255.0.0.0 | 16,777,216개 | 매우 큰 조직 |
| /16 | 255.255.0.0 | 65,536개 | VNet 전체 주소 공간 |
| /24 | 255.255.255.0 | 256개 (실제 251개) | 일반적인 Subnet |
| /27 | 255.255.255.224 | 32개 (실제 27개) | 작은 Subnet |
| /32 | 255.255.255.255 | 1개 | 단일 호스트 |

> **참고**: Azure는 각 Subnet에서 처음 4개와 마지막 1개 IP를 예약하므로 실제 사용 가능한 IP는 -5개입니다.

#### 우리 예제 분석

```hcl
address_space = ["10.0.0.0/16"]
```
- **10.0.0.0 ~ 10.0.255.255** 범위
- 총 **65,536개** IP 주소 사용 가능

```hcl
address_prefixes = ["10.0.1.0/24"]
```
- **10.0.1.0 ~ 10.0.1.255** 범위
- 총 **256개** IP (실제 사용 가능: **251개**)

### 1.3 Subnet 설계 패턴

#### 퍼블릭 vs 프라이빗 Subnet

```
┌─────────────────── VNet: 10.0.0.0/16 ───────────────────┐
│                                                           │
│  ┌─────────────────────────────────────────────────┐    │
│  │  Public Subnet: 10.0.1.0/24                     │    │
│  │  - 인터넷에서 접근 가능                          │    │
│  │  - 로드 밸런서, Bastion 호스트                   │    │
│  └─────────────────────────────────────────────────┘    │
│                                                           │
│  ┌─────────────────────────────────────────────────┐    │
│  │  Private Subnet: 10.0.3.0/24                    │    │
│  │  - 인터넷 직접 접근 불가                         │    │
│  │  - 데이터베이스, 애플리케이션 서버               │    │
│  └─────────────────────────────────────────────────┘    │
│                                                           │
└───────────────────────────────────────────────────────────┘
```

#### 설계 원칙

1. **보안 계층화** (Defense in Depth)
   - 퍼블릭: 외부에서 접근해야 하는 리소스
   - 프라이빗: 내부에서만 접근하는 리소스

2. **적절한 크기 할당**
   - 향후 확장 가능성 고려
   - 너무 크면 IP 낭비, 너무 작으면 확장 불가

3. **연속된 주소 블록 사용**
   ```hcl
   10.0.1.0/24  # Public
   10.0.2.0/24  # (예약 - 추후 사용)
   10.0.3.0/24  # Private
   ```

---

## 2. Terraform으로 네트워크 구성하기 🏗️

### 2.1 코드 분석

#### 전체 코드 구조

```hcl
# 1. 리소스 그룹 생성
resource "azurerm_resource_group" "rg" {
  name     = "rg-network-study"
  location = "Korea Central"
}

# 2. VNet 생성
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-study"
  location            = azurerm_resource_group.rg.location      # 참조!
  resource_group_name = azurerm_resource_group.rg.name          # 참조!
  address_space       = ["10.0.0.0/16"]
}

# 3. 퍼블릭 서브넷 생성
resource "azurerm_subnet" "public" {
  name                 = "subnet-public"
  resource_group_name  = azurerm_resource_group.rg.name         # 참조!
  virtual_network_name = azurerm_virtual_network.vnet.name      # 참조!
  address_prefixes     = ["10.0.1.0/24"]
}

# 4. 프라이빗 서브넷 생성
resource "azurerm_subnet" "private" {
  name                 = "subnet-private"
  resource_group_name  = azurerm_resource_group.rg.name         # 참조!
  virtual_network_name = azurerm_virtual_network.vnet.name      # 참조!
  address_prefixes     = ["10.0.3.0/24"]
}
```

### 2.2 리소스 간 의존성 (Dependency)

#### 🔗 암시적 의존성 (Implicit Dependency)

Terraform은 리소스 참조를 통해 **자동으로 의존성을 감지**합니다.

```hcl
resource "azurerm_virtual_network" "vnet" {
  resource_group_name = azurerm_resource_group.rg.name  # ← 여기서 의존성 생성
}
```

**의존성 그래프**:
```
azurerm_resource_group.rg
        ↓
azurerm_virtual_network.vnet
        ↓
azurerm_subnet.public
azurerm_subnet.private
```

Terraform이 자동으로:
1. **리소스 그룹** 먼저 생성
2. **VNet** 생성 (리소스 그룹 필요)
3. **Subnet들** 생성 (VNet 필요)

#### 🔧 명시적 의존성 (Explicit Dependency)

참조가 아닌데 순서가 필요한 경우 `depends_on` 사용:

```hcl
resource "azurerm_subnet" "example" {
  # ... 속성들 ...
  
  depends_on = [
    azurerm_network_security_group.nsg
  ]
}
```

> **Best Practice**: 가능하면 암시적 의존성(리소스 참조)을 사용하세요. 더 명확하고 안전합니다.

### 2.3 리소스 참조 문법

#### 기본 문법

```hcl
리소스타입.로컬이름.속성
```

#### 실제 예시

```hcl
# 정의
resource "azurerm_resource_group" "rg" {
  name     = "rg-network-study"
  location = "Korea Central"
}

# 참조
azurerm_resource_group.rg.name       # "rg-network-study"
azurerm_resource_group.rg.location   # "Korea Central"
azurerm_resource_group.rg.id         # Azure 리소스 ID (생성 후 알 수 있음)
```

#### 💡 왜 참조를 사용할까?

**하드코딩 방식** (나쁨 ❌):
```hcl
resource "azurerm_virtual_network" "vnet" {
  resource_group_name = "rg-network-study"  # 하드코딩
  location            = "Korea Central"      # 하드코딩
}
```

**문제점**:
- 리소스 그룹 이름을 바꾸면 VNet 코드도 수정해야 함
- 오타 가능성
- 의존성 관리 안 됨

**참조 방식** (좋음 ✅):
```hcl
resource "azurerm_virtual_network" "vnet" {
  resource_group_name = azurerm_resource_group.rg.name      # 참조
  location            = azurerm_resource_group.rg.location  # 참조
}
```

**장점**:
- 단일 진실 공급원 (Single Source of Truth)
- 의존성 자동 관리
- 리팩토링 안전

### 2.4 실행 계획 이해하기

#### terraform plan 출력 분석

```bash
$ terraform plan
```

**출력 예시**:
```
Terraform will perform the following actions:

  # azurerm_resource_group.rg will be created
  + resource "azurerm_resource_group" "rg" {
      + id       = (known after apply)
      + location = "koreacentral"
      + name     = "rg-network-study"
    }

  # azurerm_virtual_network.vnet will be created
  + resource "azurerm_virtual_network" "vnet" {
      + address_space       = [
          + "10.0.0.0/16",
        ]
      + id                  = (known after apply)
      + location            = "koreacentral"
      + name                = "vnet-study"
      + resource_group_name = "rg-network-study"
      + subnet              = (known after apply)
    }

  # azurerm_subnet.public will be created
  + resource "azurerm_subnet" "public" {
      + address_prefixes     = [
          + "10.0.1.0/24",
        ]
      + id                   = (known after apply)
      + name                 = "subnet-public"
      + resource_group_name  = "rg-network-study"
      + virtual_network_name = "vnet-study"
    }

  # azurerm_subnet.private will be created
  + resource "azurerm_subnet" "private" {
      + address_prefixes     = [
          + "10.0.3.0/24",
        ]
      + id                   = (known after apply)
      + name                 = "subnet-private"
      + resource_group_name  = "rg-network-study"
      + virtual_network_name = "vnet-study"
    }

Plan: 4 to add, 0 to change, 0 to destroy.
```

#### 주목할 점

1. **`(known after apply)`**: 리소스가 생성된 후에야 알 수 있는 값
   - 리소스 ID
   - 동적 IP 주소 등

2. **생성 순서**: Terraform이 의존성에 따라 자동으로 순서 결정

3. **총계**: `Plan: 4 to add, 0 to change, 0 to destroy`

---

## 3. 실습: 직접 실행해보기 🚀

### 3.1 기본 실행

```bash
# 1. 초기화
terraform init

# 2. 계획 확인
terraform plan

# 3. 적용
terraform apply
```

### 3.2 상태 확인

```bash
# 모든 리소스 보기
terraform show

# 리소스 목록
terraform state list
```

**출력 예시**:
```
azurerm_resource_group.rg
azurerm_virtual_network.vnet
azurerm_subnet.public
azurerm_subnet.private
```

### 3.3 특정 리소스 정보 확인

```bash
# VNet 정보만 보기
terraform state show azurerm_virtual_network.vnet
```

**출력 예시**:
```
resource "azurerm_virtual_network" "vnet" {
    address_space       = [
        "10.0.0.0/16",
    ]
    id                  = "/subscriptions/.../vnet-study"
    location            = "koreacentral"
    name                = "vnet-study"
    resource_group_name = "rg-network-study"
}
```

---

## 4. 네트워크 설계 패턴 🎨

### 4.1 실무에서 자주 쓰는 패턴

#### 패턴 1: 3-Tier 아키텍처

```
VNet: 10.0.0.0/16
├── Web Tier (Public):     10.0.1.0/24
├── App Tier (Private):    10.0.2.0/24
└── DB Tier (Private):     10.0.3.0/24
```

**Terraform 코드**:
```hcl
resource "azurerm_subnet" "web" {
  name             = "subnet-web"
  address_prefixes = ["10.0.1.0/24"]
  # ...
}

resource "azurerm_subnet" "app" {
  name             = "subnet-app"
  address_prefixes = ["10.0.2.0/24"]
  # ...
}

resource "azurerm_subnet" "db" {
  name             = "subnet-db"
  address_prefixes = ["10.0.3.0/24"]
  # ...
}
```

#### 패턴 2: Hub-Spoke 토폴로지

```
Hub VNet (10.0.0.0/16)
├── Shared Services
│
└── Peering
    │
    ├── Spoke 1 (10.1.0.0/16) - 개발 환경
    ├── Spoke 2 (10.2.0.0/16) - 스테이징 환경
    └── Spoke 3 (10.3.0.0/16) - 프로덕션 환경
```

#### 패턴 3: 환경별 분리

```
Dev VNet:   10.0.0.0/16
Stage VNet: 10.1.0.0/16
Prod VNet:  10.2.0.0/16
```

### 4.2 IP 주소 계획 베스트 프랙티스

#### ✅ 좋은 예

```hcl
# 확장 가능하고 체계적
VNet:              10.0.0.0/16    (65,536 IPs)
  Public Subnet:   10.0.1.0/24    (251 IPs)
  App Subnet:      10.0.10.0/24   (251 IPs)
  DB Subnet:       10.0.20.0/24   (251 IPs)
  Reserved:        10.0.50.0/24   (추후 사용)
```

#### ❌ 나쁜 예

```hcl
# 확장 어렵고 비체계적
VNet:              10.0.0.0/16
  Subnet 1:        10.0.0.0/24
  Subnet 2:        10.0.1.0/24
  Subnet 3:        10.0.2.0/24
  # 연속적이어서 중간에 추가 어려움
```

### 4.3 보안 고려사항

#### NSG(Network Security Group) 통합

다음 폴더에서 다루겠지만, 기본 개념:

```hcl
resource "azurerm_subnet" "web" {
  name             = "subnet-web"
  address_prefixes = ["10.0.1.0/24"]
  # ...
}

# NSG 연결 (다음 단계)
resource "azurerm_subnet_network_security_group_association" "web_nsg" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.web_nsg.id
}
```

---

## 5. 트러블슈팅 및 팁 🔧

### 5.1 자주 발생하는 오류

#### 오류 1: 주소 공간 중복

```
Error: subnet address prefix overlaps with existing subnet
```

**원인**: Subnet 주소 범위가 겹침
```hcl
address_prefixes = ["10.0.1.0/24"]  # 10.0.1.0 ~ 10.0.1.255
address_prefixes = ["10.0.1.0/25"]  # 10.0.1.0 ~ 10.0.1.127 (겹침!)
```

**해결**: 서로 다른 범위 사용
```hcl
address_prefixes = ["10.0.1.0/24"]  # 10.0.1.0 ~ 10.0.1.255
address_prefixes = ["10.0.2.0/24"]  # 10.0.2.0 ~ 10.0.2.255 (안 겹침)
```

#### 오류 2: 주소 범위가 VNet을 벗어남

```
Error: subnet address prefix is not within the address space
```

**원인**: Subnet이 VNet 범위 밖
```hcl
address_space    = ["10.0.0.0/16"]   # VNet: 10.0.x.x만 가능
address_prefixes = ["10.1.0.0/24"]   # 10.1.x.x는 범위 밖!
```

**해결**: VNet 범위 내 주소 사용
```hcl
address_prefixes = ["10.0.1.0/24"]   # 10.0.x.x로 수정
```

#### 오류 3: Subnet 삭제 실패

```
Error: subnet is in use and cannot be deleted
```

**원인**: Subnet에 리소스가 연결되어 있음

**해결 순서**:
1. Subnet 내 리소스(VM 등) 먼저 삭제
2. 그 다음 Subnet 삭제

### 5.2 유용한 명령어

```bash
# 특정 리소스만 생성
terraform apply -target=azurerm_virtual_network.vnet

# 특정 리소스만 삭제
terraform destroy -target=azurerm_subnet.private

# 그래프로 의존성 확인 (Graphviz 필요)
terraform graph | dot -Tpng > graph.png
```

### 5.3 Best Practices 체크리스트

- [ ] VNet 주소 공간은 충분히 크게 (최소 /16 권장)
- [ ] Subnet은 용도별로 명확히 분리
- [ ] 리소스 참조 사용 (하드코딩 지양)
- [ ] 네트워크 명명 규칙 일관성 유지
- [ ] 향후 확장 가능성 고려한 IP 할당
- [ ] 문서화 (주석으로 각 Subnet 용도 설명)

---

## 6. 학습 체크리스트 📚

### ✅ Azure 네트워크 개념
- [ ] VNet의 역할과 특징 이해
- [ ] CIDR 표기법 이해
- [ ] Subnet의 목적과 설계 원칙
- [ ] Public vs Private Subnet 차이

### ✅ Terraform 기법
- [ ] 리소스 참조 문법 숙지
- [ ] 암시적 의존성 vs 명시적 의존성
- [ ] 의존성 그래프 이해
- [ ] terraform plan 출력 해석 능력

### ✅ 실무 스킬
- [ ] 3-Tier 아키텍처 설계
- [ ] IP 주소 계획 수립
- [ ] 네트워크 문제 트러블슈팅
- [ ] 체계적인 명명 규칙 적용

---

## 🎓 선생님의 마무리 조언

### 이번 폴더에서 배운 핵심

1. **리소스 참조**: Terraform의 가장 강력한 기능 중 하나
   ```hcl
   azurerm_resource_group.rg.name  # 이렇게 참조하세요!
   ```

2. **의존성 관리**: Terraform이 자동으로 순서를 결정
   - 직접 순서를 제어할 필요 없음
   - 참조만 올바르게 하면 OK

3. **네트워크 설계**: 인프라의 기초
   - 체계적인 IP 계획
   - 보안을 고려한 Subnet 분리

### 다음 단계

다음 폴더에서는:
- **NSG (Network Security Group)** - 방화벽 규칙
- **보안 규칙 설정**
- **인바운드/아웃바운드 트래픽 제어**

### 실습 과제 (선택)

시간이 있다면 해보세요:

1. **AKS용 Subnet 추가**
   ```hcl
   resource "azurerm_subnet" "aks" {
     name             = "subnet-aks"
     address_prefixes = ["10.0.10.0/24"]
     # ...
   }
   ```

2. **다른 Region에 동일한 구조 복제**
   - Location만 변경해서 실행해보기

3. **더 세분화된 Subnet 설계**
   - Web, App, DB, Management, AKS 등

---

**다음 폴더에서 만나요!** 🚀 NSG로 네트워크 보안을 강화해봅시다.
