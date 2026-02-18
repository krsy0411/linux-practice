# Azure NSG (Network Security Group) with Terraform

> **학습 목표**: Azure NSG를 이해하고, Terraform으로 네트워크 보안 규칙을 관리하는 방법을 학습합니다.

---

## 1. NSG (Network Security Group) 개념 🛡️

### 1.1 NSG란?

**NSG**는 Azure에서 제공하는 **네트워크 수준의 방화벽**입니다.

#### 🔐 현실 세계 비유
- **NSG** = 건물 입구의 보안 게이트
- **보안 규칙** = 출입 허가 목록
- **트래픽** = 건물에 드나드는 사람들

#### 핵심 특징

| 특징 | 설명 |
|------|------|
| **무상태** (Stateful) | 허용된 인바운드는 자동으로 아웃바운드 허용 |
| **우선순위 기반** | 낮은 숫자가 먼저 평가 (100 → 200 → 300) |
| **5-Tuple** | 출발지, 목적지, 프로토콜, 포트로 트래픽 식별 |
| **기본 규칙** | 자동으로 추가되는 시스템 규칙 존재 |
| **계층 적용** | Subnet 또는 NIC(Network Interface)에 적용 |

### 1.2 NSG가 필요한 이유

#### ❌ NSG 없이는...

```
인터넷
    ↓ (모든 트래픽 허용)
┌───────────────┐
│   Web Server  │  👈 누구나 접근 가능 (위험!)
└───────────────┘
```

**문제점**:
- 모든 포트가 열려있음
- SSH, RDP 등 관리 포트 노출
- 공격 표면 증가
- 데이터베이스 직접 접근 가능

#### ✅ NSG 적용 후

```
인터넷
    ↓
┌─────── NSG (Firewall) ──────┐
│ ✅ 80번 포트 (HTTP) 허용     │
│ ✅ 443번 포트 (HTTPS) 허용   │
│ ❌ 22번 포트 (SSH) 차단      │
│ ❌ 3389번 포트 (RDP) 차단    │
│ ❌ 기타 모든 포트 차단       │
└─────────────────────────────┘
    ↓ (허용된 트래픽만)
┌───────────────┐
│   Web Server  │  👈 안전!
└───────────────┘
```

### 1.3 인바운드 vs 아웃바운드

#### 📥 Inbound (인바운드)
외부에서 리소스**로 들어오는** 트래픽

```
인터넷 → NSG → VM
```

**예시**:
- 사용자가 웹사이트 접속 (외부 → 웹서버)
- SSH로 서버 접속 (관리자 PC → 서버)

#### 📤 Outbound (아웃바운드)
리소스**에서 외부로 나가는** 트래픽

```
VM → NSG → 인터넷
```

**예시**:
- 서버가 패키지 다운로드 (서버 → 인터넷)
- 데이터베이스가 외부 API 호출 (DB → 외부 서비스)

---

## 2. NSG 구조 이해하기 🏗️

### 2.1 보안 규칙 (Security Rule)

하나의 NSG는 **여러 개의 보안 규칙**을 가질 수 있습니다.

#### 규칙의 구성 요소

```hcl
resource "azurerm_network_security_rule" "web_http" {
  name                        = "allow-http"         # 규칙 이름
  priority                    = 100                  # 우선순위 (100-4096)
  direction                   = "Inbound"            # 방향
  access                      = "Allow"              # 허용/차단
  protocol                    = "Tcp"                # 프로토콜
  source_port_range           = "*"                  # 출발지 포트
  destination_port_range      = "80"                 # 목적지 포트
  source_address_prefix       = "*"                  # 출발지 IP
  destination_address_prefix  = "*"                  # 목적지 IP
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.web_nsg.name
}
```

#### 각 속성 설명

| 속성 | 설명 | 가능한 값 |
|------|------|----------|
| **name** | 규칙의 고유 이름 | 영문, 숫자, 하이픈 |
| **priority** | 우선순위 (낮을수록 먼저) | 100 ~ 4096 |
| **direction** | 트래픽 방향 | `Inbound`, `Outbound` |
| **access** | 허용/차단 | `Allow`, `Deny` |
| **protocol** | 프로토콜 | `Tcp`, `Udp`, `Icmp`, `*` (모두) |
| **source_port_range** | 출발지 포트 | `*`, `80`, `443`, `1024-65535` |
| **destination_port_range** | 목적지 포트 | `*`, `80`, `443`, `1024-65535` |
| **source_address_prefix** | 출발지 IP | `*`, CIDR, Service Tag |
| **destination_address_prefix** | 목적지 IP | `*`, CIDR, Service Tag |

### 2.2 우선순위 (Priority) 작동 방식

NSG는 **위에서 아래로 순차적으로 평가**합니다.

#### 예시: 우선순위가 중요한 이유

```hcl
# 규칙 1: Priority 100
resource "azurerm_network_security_rule" "deny_all_ssh" {
  name                   = "deny-all-ssh"
  priority               = 100
  direction              = "Inbound"
  access                 = "Deny"
  protocol               = "Tcp"
  destination_port_range = "22"
  source_address_prefix  = "*"
  # ...
}

# 규칙 2: Priority 200
resource "azurerm_network_security_rule" "allow_admin_ssh" {
  name                   = "allow-admin-ssh"
  priority               = 200
  direction              = "Inbound"
  access                 = "Allow"
  protocol               = "Tcp"
  destination_port_range = "22"
  source_address_prefix  = "203.0.113.0/24"  # 관리자 IP
  # ...
}
```

**❌ 문제**: 우선순위 100이 먼저 평가되어 모든 SSH를 차단
→ 우선순위 200의 허용 규칙은 **절대 실행되지 않음**

**✅ 해결**: 순서 바꾸기

```hcl
# 규칙 1: Priority 100 - 특정 IP는 허용
resource "azurerm_network_security_rule" "allow_admin_ssh" {
  priority               = 100  # 먼저 평가
  access                 = "Allow"
  destination_port_range = "22"
  source_address_prefix  = "203.0.113.0/24"
  # ...
}

# 규칙 2: Priority 200 - 나머지는 차단
resource "azurerm_network_security_rule" "deny_all_ssh" {
  priority               = 200  # 나중에 평가
  access                 = "Deny"
  destination_port_range = "22"
  source_address_prefix  = "*"
  # ...
}
```

**작동 방식**:
1. 관리자 IP (203.0.113.0/24)에서 오는 SSH → 규칙 1 매칭 → **허용**
2. 다른 IP에서 오는 SSH → 규칙 1 불일치, 규칙 2 매칭 → **차단**

### 2.3 기본 규칙 (Default Rules)

Azure는 모든 NSG에 **자동으로 기본 규칙을 추가**합니다.

#### 인바운드 기본 규칙

| Priority | Name | 설명 |
|----------|------|------|
| 65000 | AllowVnetInBound | 같은 VNet 내 통신 허용 |
| 65001 | AllowAzureLoadBalancerInBound | Azure LB 헬스체크 허용 |
| 65500 | DenyAllInBound | **나머지 모두 차단** |

#### 아웃바운드 기본 규칙

| Priority | Name | 설명 |
|----------|------|------|
| 65000 | AllowVnetOutBound | 같은 VNet 내 통신 허용 |
| 65001 | AllowInternetOutBound | 인터넷으로 나가는 트래픽 허용 |
| 65500 | DenyAllOutBound | 나머지 모두 차단 |

**💡 핵심**: 
- 기본적으로 **인바운드는 모두 차단**, **아웃바운드는 인터넷 허용**
- 필요한 인바운드 트래픽만 명시적으로 허용해야 함

---

## 3. Terraform 코드 분석 🔍

### 3.1 전체 구조

우리 예제는 **3-Tier 아키텍처**를 구현합니다:

```
┌─────────────────── VNet: 10.0.0.0/16 ───────────────────┐
│                                                           │
│  ┌─────────────────────────────────────────────────┐    │
│  │  Web Subnet: 10.0.1.0/24                        │    │
│  │  + Web NSG (HTTP/HTTPS 허용)                    │    │
│  └─────────────────────────────────────────────────┘    │
│                     ↓ (내부 통신)                        │
│  ┌─────────────────────────────────────────────────┐    │
│  │  App Subnet: 10.0.2.0/24                        │    │
│  │  (NSG 없음 - 다음 단계에서 추가)                 │    │
│  └─────────────────────────────────────────────────┘    │
│                     ↓ (내부 통신)                        │
│  ┌─────────────────────────────────────────────────┐    │
│  │  DB Subnet: 10.0.3.0/24                         │    │
│  │  (NSG 없음 - 다음 단계에서 추가)                 │    │
│  └─────────────────────────────────────────────────┘    │
│                                                           │
└───────────────────────────────────────────────────────────┘
```

### 3.2 코드 단계별 분석

#### Step 1: 네트워크 인프라 생성

```hcl
# 리소스 그룹
resource "azurerm_resource_group" "rg" {
  name     = "rg-network-study"
  location = "Korea Central"
}

# VNet
resource "azurerm_virtual_network" "main" {
  name                = "vnet-study"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

# Subnet들
resource "azurerm_subnet" "web" {
  name                 = "web-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "app" {
  name                 = "app-subnet"
  address_prefixes     = ["10.0.2.0/24"]
  # ...
}

resource "azurerm_subnet" "db" {
  name                 = "db-subnet"
  address_prefixes     = ["10.0.3.0/24"]
  # ...
}
```

**의존성**:
```
Resource Group
    ↓
Virtual Network
    ↓
Subnets (web, app, db)
```

#### Step 2: NSG 생성

```hcl
resource "azurerm_network_security_group" "web_nsg" {
  name                = "web-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
```

**특징**:
- NSG는 **빈 컨테이너**로 생성됨
- 규칙은 별도로 추가해야 함
- 여러 Subnet에 재사용 가능 (권장하지 않음)

#### Step 3: 보안 규칙 추가

```hcl
resource "azurerm_network_security_rule" "web_http" {
  name                        = "allow-http"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"                 # 출발지 포트는 랜덤
  destination_port_range      = "80"                # 목적지 80번 포트
  source_address_prefix       = "*"                 # 모든 IP에서
  destination_address_prefix  = "*"                 # 모든 목적지로
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.web_nsg.name
}
```

**의미 해석**:
> "모든 출발지에서 TCP 80번 포트로 들어오는 인바운드 트래픽을 허용한다"

#### Step 4: NSG를 Subnet에 연결

```hcl
resource "azurerm_subnet_network_security_group_association" "web_assoc" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.web_nsg.id
}
```

**연결 관계**:
```
web_subnet ← (association) ← web_nsg
```

**의존성 체인**:
```
azurerm_subnet.web
    ↓
azurerm_network_security_group.web_nsg
    ↓
azurerm_network_security_rule.web_http
    ↓
azurerm_subnet_network_security_group_association.web_assoc
```

### 3.3 리소스 참조 패턴

#### ID 참조

```hcl
subnet_id                 = azurerm_subnet.web.id
network_security_group_id = azurerm_network_security_group.web_nsg.id
```

**ID란?**
- Azure 리소스의 고유 식별자
- 형식: `/subscriptions/{sub-id}/resourceGroups/{rg}/providers/{provider}/{type}/{name}`
- 생성 후에만 알 수 있음 (`known after apply`)

#### Name 참조

```hcl
resource_group_name         = azurerm_resource_group.rg.name
network_security_group_name = azurerm_network_security_group.web_nsg.name
```

**언제 사용?**
- ID: 리소스 간 연결 (Association, Link)
- Name: 같은 리소스 그룹 내에서 이름으로 참조

---

## 4. 실전 보안 규칙 작성 🎯

### 4.1 일반적인 웹 애플리케이션 규칙

#### HTTP/HTTPS 허용

```hcl
# HTTP
resource "azurerm_network_security_rule" "allow_http" {
  name                       = "allow-http"
  priority                   = 100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "80"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  # ...
}

# HTTPS
resource "azurerm_network_security_rule" "allow_https" {
  name                       = "allow-https"
  priority                   = 110
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  destination_port_range     = "443"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  # ...
}
```

#### SSH (특정 IP만 허용)

```hcl
resource "azurerm_network_security_rule" "allow_ssh_admin" {
  name                       = "allow-ssh-from-admin"
  priority                   = 120
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  destination_port_range     = "22"
  source_address_prefix      = "203.0.113.10/32"  # 관리자 IP
  destination_address_prefix = "*"
  # ...
}
```

### 4.2 애플리케이션 계층 규칙

```hcl
# App 서버 NSG
resource "azurerm_network_security_group" "app_nsg" {
  name                = "app-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Web 서브넷에서만 접근 허용
resource "azurerm_network_security_rule" "app_from_web" {
  name                       = "allow-from-web-subnet"
  priority                   = 100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  destination_port_range     = "8080"
  source_address_prefix      = "10.0.1.0/24"      # Web Subnet만!
  destination_address_prefix = "*"
  network_security_group_name = azurerm_network_security_group.app_nsg.name
  # ...
}
```

### 4.3 데이터베이스 계층 규칙

```hcl
# DB 서버 NSG
resource "azurerm_network_security_group" "db_nsg" {
  name                = "db-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# App 서브넷에서만 PostgreSQL 접근 허용
resource "azurerm_network_security_rule" "db_from_app" {
  name                       = "allow-postgresql-from-app"
  priority                   = 100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  destination_port_range     = "5432"
  source_address_prefix      = "10.0.2.0/24"      # App Subnet만!
  destination_address_prefix = "*"
  network_security_group_name = azurerm_network_security_group.db_nsg.name
  # ...
}
```

### 4.4 포트 범위와 여러 포트 지정

#### 포트 범위

```hcl
# 높은 포트 범위 허용 (동적 포트)
resource "azurerm_network_security_rule" "allow_ephemeral" {
  destination_port_range = "1024-65535"
  # ...
}
```

#### 여러 포트 지정

```hcl
# 복수 포트는 _ranges 사용
resource "azurerm_network_security_rule" "allow_web_ports" {
  destination_port_ranges = ["80", "443", "8080"]  # 리스트!
  # destination_port_range는 사용 불가
  # ...
}
```

### 4.5 Service Tags 활용

**Service Tags**는 Azure 서비스의 IP 범위를 자동으로 관리해주는 별칭입니다.

```hcl
# Azure Storage에서만 접근 허용
resource "azurerm_network_security_rule" "allow_from_storage" {
  name                       = "allow-from-storage"
  priority                   = 100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  destination_port_range     = "443"
  source_address_prefix      = "Storage"  # Service Tag!
  destination_address_prefix = "*"
  # ...
}
```

**주요 Service Tags**:

| Tag | 설명 |
|-----|------|
| `Internet` | 퍼블릭 인터넷 주소 공간 |
| `VirtualNetwork` | 모든 VNet 주소 공간 |
| `AzureLoadBalancer` | Azure Load Balancer |
| `Storage` | Azure Storage 서비스 |
| `Sql` | Azure SQL Database |
| `AzureMonitor` | Azure Monitor 서비스 |

**장점**:
- IP 범위가 변경되어도 자동 업데이트
- 여러 IP 범위를 하나의 태그로 관리
- 가독성 향상

---

## 5. 심화: NSG 설계 패턴 🎨

### 5.1 Defense in Depth (심층 방어)

여러 계층에 보안을 적용하여 공격 표면을 최소화합니다.

```
┌─── Layer 1: Front Door / Application Gateway
│
├─── Layer 2: Web Subnet NSG
│      - HTTP/HTTPS만 허용
│      - SSH는 Bastion에서만
│
├─── Layer 3: App Subnet NSG
│      - Web Subnet에서만 허용
│      - 외부 접근 차단
│
└─── Layer 4: DB Subnet NSG
       - App Subnet에서만 허용
       - 외부 완전 차단
```

### 5.2 Deny by Default (기본 차단)

**원칙**: 필요한 것만 명시적으로 허용, 나머지는 모두 차단

```hcl
# ✅ 좋은 예: 필요한 것만 허용
resource "azurerm_network_security_rule" "allow_https" {
  priority               = 100
  access                 = "Allow"
  destination_port_range = "443"
  # ...
}
# 나머지는 기본 규칙(65500)에 의해 자동 차단

# ❌ 나쁜 예: 모든 것 허용하고 일부만 차단
resource "azurerm_network_security_rule" "allow_all" {
  priority               = 100
  access                 = "Allow"
  destination_port_range = "*"  # 위험!
  # ...
}
```

### 5.3 최소 권한 원칙 (Least Privilege)

**가능한 한 좁은 범위로 제한**합니다.

#### ❌ 너무 넓음

```hcl
source_address_prefix = "*"                    # 전 세계 모든 IP
destination_port_range = "*"                   # 모든 포트
```

#### ✅ 적절함

```hcl
source_address_prefix = "10.0.1.0/24"         # 특정 Subnet
destination_port_range = "5432"               # 특정 포트
```

### 5.4 NSG 명명 규칙

일관된 명명 규칙으로 관리를 쉽게:

```hcl
# NSG 이름: {tier}-nsg
web-nsg
app-nsg
db-nsg
mgmt-nsg

# 규칙 이름: {action}-{service}-{direction}-{from/to}
allow-http-inbound-internet
allow-ssh-inbound-bastion
deny-rdp-inbound-internet
allow-sql-inbound-app
```

---

## 6. 실습 및 검증 🚀

### 6.1 기본 실행

```bash
# 초기화
terraform init

# 계획 확인
terraform plan

# 적용
terraform apply
```

### 6.2 생성된 NSG 확인

```bash
# 모든 리소스 보기
terraform state list

# NSG 상세 정보
terraform state show azurerm_network_security_group.web_nsg
```

**출력 예시**:
```
resource "azurerm_network_security_group" "web_nsg" {
    id                  = "/subscriptions/.../web-nsg"
    location            = "koreacentral"
    name                = "web-nsg"
    resource_group_name = "rg-network-study"
    security_rule       = [
        {
            name                       = "allow-http"
            priority                   = 100
            direction                  = "Inbound"
            access                     = "Allow"
            protocol                   = "Tcp"
            destination_port_range     = "80"
            # ...
        }
    ]
}
```

### 6.3 Azure Portal에서 확인

1. Azure Portal 접속
2. 리소스 그룹 `rg-network-study` 선택
3. `web-nsg` 선택
4. "인바운드 보안 규칙" 메뉴 확인

**확인 사항**:
- 우리가 만든 규칙: Priority 100 (allow-http)
- 기본 규칙들: Priority 65000~65500

### 6.4 규칙 추가 실습

**과제**: HTTPS 규칙 추가하기

```hcl
resource "azurerm_network_security_rule" "web_https" {
  name                        = "allow-https"
  priority                    = 110                    # HTTP 다음
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"                 # HTTPS 포트
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.web_nsg.name
}
```

**실행**:
```bash
terraform plan   # +1 추가 확인
terraform apply
```

---

## 7. 트러블슈팅 🔧

### 7.1 자주 발생하는 오류

#### 오류 1: 우선순위 중복

```
Error: network security rule priority "100" already exists
```

**원인**: 같은 NSG 내에서 동일한 우선순위 사용

**해결**:
```hcl
priority = 100  # 첫 번째 규칙
priority = 110  # 두 번째 규칙 (다른 번호)
priority = 120  # 세 번째 규칙
```

#### 오류 2: Association 충돌

```
Error: A Network Security Group is already associated with the Subnet
```

**원인**: Subnet에 이미 다른 NSG가 연결되어 있음

**해결**:
```bash
# 기존 association 삭제
terraform destroy -target=azurerm_subnet_network_security_group_association.old_assoc

# 새 association 생성
terraform apply
```

#### 오류 3: 규칙 이름 중복

```
Error: security rule name "allow-http" already exists
```

**원인**: 같은 NSG 내에서 동일한 규칙 이름 사용

**해결**: 고유한 이름 사용
```hcl
name = "allow-http-from-lb"      # 명확하고 고유하게
name = "allow-https-from-cdn"
```

### 7.2 디버깅 팁

#### NSG 플로우 로그 활성화

```hcl
resource "azurerm_network_watcher_flow_log" "nsg_flow_log" {
  network_watcher_name = "NetworkWatcher_koreacentral"
  resource_group_name  = "NetworkWatcherRG"
  
  network_security_group_id = azurerm_network_security_group.web_nsg.id
  storage_account_id        = azurerm_storage_account.logs.id
  enabled                   = true
  
  retention_policy {
    enabled = true
    days    = 7
  }
}
```

**활용**:
- 어떤 트래픽이 차단/허용되었는지 확인
- 보안 규칙 최적화
- 문제 진단

#### Azure CLI로 규칙 확인

```bash
# NSG의 모든 규칙 보기
az network nsg show \
  --name web-nsg \
  --resource-group rg-network-study \
  --query "securityRules[*].{Name:name, Priority:priority, Access:access, Direction:direction, Port:destinationPortRange}"
```

---

## 8. Best Practices 체크리스트 ✅

### 보안

- [ ] 기본 차단 원칙 (Deny by Default) 적용
- [ ] 최소 권한 원칙으로 규칙 작성
- [ ] SSH/RDP는 특정 IP에서만 허용
- [ ] 관리 포트는 Bastion Host 사용
- [ ] Service Tags 적극 활용
- [ ] 주기적인 규칙 검토 및 정리

### 설계

- [ ] 계층별로 NSG 분리 (web, app, db)
- [ ] 우선순위 간격 두기 (100, 110, 120... 중간 추가 가능)
- [ ] 명확한 명명 규칙 적용
- [ ] 문서화 (주석으로 각 규칙 설명)

### Terraform

- [ ] NSG 규칙을 별도 리소스로 관리
- [ ] 리소스 참조 사용 (하드코딩 금지)
- [ ] 변수화 고려 (포트 번호, IP 범위 등)
- [ ] 모듈화 검토 (재사용 가능성)

### 운영

- [ ] NSG 플로우 로그 활성화
- [ ] Azure Monitor 알림 설정
- [ ] 정기적인 보안 검토
- [ ] 변경 사항 Git으로 관리

---

## 9. 다음 단계로 🎯

### 9.1 이번 폴더에서 배운 것

- ✅ NSG의 개념과 필요성
- ✅ 인바운드/아웃바운드 트래픽 제어
- ✅ 보안 규칙 작성 방법
- ✅ 우선순위와 평가 순서
- ✅ NSG를 Subnet에 연결하는 방법

### 9.2 실습 과제 (선택)

시간이 있다면 도전해보세요:

#### 과제 1: App과 DB Subnet에 NSG 추가

```hcl
# App NSG 생성
resource "azurerm_network_security_group" "app_nsg" {
  name                = "app-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Web에서만 App으로 접근 허용
resource "azurerm_network_security_rule" "app_from_web" {
  name                       = "allow-from-web"
  priority                   = 100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  destination_port_range     = "8080"
  source_address_prefix      = "10.0.1.0/24"  # Web Subnet
  destination_address_prefix = "*"
  network_security_group_name = azurerm_network_security_group.app_nsg.name
  resource_group_name         = azurerm_resource_group.rg.name
}

# App NSG를 Subnet에 연결
resource "azurerm_subnet_network_security_group_association" "app_assoc" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app_nsg.id
}
```

#### 과제 2: 거부 규칙 추가

```hcl
# 특정 IP 차단
resource "azurerm_network_security_rule" "deny_suspicious_ip" {
  name                       = "deny-suspicious-ip"
  priority                   = 90                     # 허용 규칙보다 우선
  direction                  = "Inbound"
  access                     = "Deny"
  protocol                   = "*"
  source_address_prefix      = "198.51.100.0/24"    # 차단할 IP
  destination_address_prefix = "*"
  # ...
}
```

#### 과제 3: 아웃바운드 규칙 추가

```hcl
# 특정 외부 API만 호출 허용
resource "azurerm_network_security_rule" "allow_api_outbound" {
  name                       = "allow-external-api"
  priority                   = 100
  direction                  = "Outbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  destination_port_range     = "443"
  source_address_prefix      = "*"
  destination_address_prefix = "203.0.113.50/32"  # 특정 API 서버
  # ...
}

# 나머지 인터넷 차단 (선택적)
resource "azurerm_network_security_rule" "deny_internet_outbound" {
  priority                   = 200
  direction                  = "Outbound"
  access                     = "Deny"
  destination_address_prefix = "Internet"  # Service Tag
  # ...
}
```

### 9.3 다음 학습 주제

다음 폴더에서는:
- **완전한 3-Tier 아키텍처** 구현
- **Variables를 활용한 유연한 설정**
- **여러 환경 관리** (Dev, Prod)
- **실제 VM 배포**

---

## 🔗 참고 자료

- [Azure NSG 공식 문서](https://learn.microsoft.com/azure/virtual-network/network-security-groups-overview)
- [NSG 규칙 우선순위](https://learn.microsoft.com/azure/virtual-network/network-security-group-how-it-works)
- [Service Tags 목록](https://learn.microsoft.com/azure/virtual-network/service-tags-overview)
- [Terraform azurerm_network_security_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group)

---

**여기까지 수고하셨습니다!** 🎉 이제 Azure 네트워크 보안의 핵심을 이해하셨습니다. 다음 단계로 넘어가봅시다! 🚀
