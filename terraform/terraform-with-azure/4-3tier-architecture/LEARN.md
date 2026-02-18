# 3-Tier Architecture with Terraform

> **학습 목표**: 완전한 3-Tier 아키텍처를 Terraform으로 구현하고, Variables를 활용한 유연한 인프라 관리를 학습합니다.

---

## 1. 3-Tier 아키텍처란? 🏗️

### 1.1 아키텍처 개념

**3-Tier Architecture**는 애플리케이션을 **세 개의 논리적 계층**으로 분리하는 소프트웨어 아키텍처 패턴입니다.

```
┌─────────────────────────────────────────────────────────┐
│                      사용자                              │
│                        ↓                                 │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Presentation Tier (프레젠테이션 계층)           │   │
│  │  - Web Servers                                  │   │
│  │  - 사용자 인터페이스                             │   │
│  │  - 80/443 포트 (HTTP/HTTPS)                    │   │
│  │  - Public IP 보유                               │   │
│  └─────────────────────────────────────────────────┘   │
│                        ↓                                 │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Application Tier (애플리케이션 계층)            │   │
│  │  - App Servers                                  │   │
│  │  - 비즈니스 로직                                 │   │
│  │  - 8080 포트                                    │   │
│  │  - Private IP만 (인터넷 미노출)                 │   │
│  └─────────────────────────────────────────────────┘   │
│                        ↓                                 │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Data Tier (데이터 계층)                         │   │
│  │  - Database Servers                             │   │
│  │  - 데이터 저장                                   │   │
│  │  - 3306 포트 (MySQL)                            │   │
│  │  - Private IP만 (최대 보안)                     │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### 1.2 각 계층의 역할

#### 📱 Presentation Tier (Web 계층)

| 속성 | 설명 |
|------|------|
| **역할** | 사용자 인터페이스 제공 |
| **서비스** | Nginx, Apache, IIS |
| **네트워크** | Public IP, 인터넷 접근 가능 |
| **포트** | 80 (HTTP), 443 (HTTPS) |
| **보안** | 인터넷 트래픽 필터링 필수 |

**예시**:
- 웹 브라우저로 접속하는 웹사이트
- 정적 파일 제공 (HTML, CSS, JS)
- 사용자 요청을 App 계층으로 전달

#### ⚙️ Application Tier (App 계층)

| 속성 | 설명 |
|------|------|
| **역할** | 비즈니스 로직 처리 |
| **서비스** | Node.js, Spring Boot, Django |
| **네트워크** | Private IP, Web 계층만 접근 |
| **포트** | 8080, 3000, 5000 등 |
| **보안** | Web Subnet에서만 인바운드 허용 |

**예시**:
- API 서버
- 인증/인가 처리
- 데이터 가공 및 비즈니스 규칙 적용

#### 🗄️ Data Tier (DB 계층)

| 속성 | 설명 |
|------|------|
| **역할** | 데이터 저장 및 관리 |
| **서비스** | MySQL, PostgreSQL, MongoDB |
| **네트워크** | Private IP, App 계층만 접근 |
| **포트** | 3306 (MySQL), 5432 (PostgreSQL) |
| **보안** | App Subnet에서만 인바운드 허용 |

**예시**:
- 사용자 데이터 저장
- 트랜잭션 관리
- 데이터 쿼리 처리

### 1.3 왜 3-Tier로 분리할까?

#### ✅ 장점

**1. 보안 강화** 🔒
```
인터넷 → [방화벽] → Web → [방화벽] → App → [방화벽] → DB
```
- 각 계층마다 방화벽 (NSG) 설치
- DB는 인터넷에서 직접 접근 불가
- 계층별 최소 권한 적용

**2. 확장성** 📈
```
Web: 3대
App: 5대  ← 부하에 따라 독립적으로 확장
DB: 2대
```
- 각 계층을 독립적으로 스케일
- 부하가 많은 계층만 늘림
- 비용 최적화

**3. 유지보수성** 🔧
```
Web 업데이트 → App/DB 영향 없음
App 업데이트 → Web/DB 영향 없음
```
- 계층별 독립적 배포
- 장애 격리 (한 계층 문제가 다른 계층에 전파 안 됨)
- 팀별 역할 분담 용이

**4. 재사용성** ♻️
```
Web 1 ─┐
Web 2 ─┼→ App ─→ DB
Web 3 ─┘
```
- 여러 Web 서버가 같은 App/DB 공유
- 중복 제거

#### ❌ 단점 (알아두기)

- 복잡도 증가 (관리할 리소스 많아짐)
- 네트워크 레이턴시 (계층 간 통신 오버헤드)
- 초기 구축 비용 (작은 서비스는 오버엔지니어링)

---

## 2. 우리가 구현할 아키텍처 📐

### 2.1 전체 구조도

```
Azure Cloud: Korea Central
┌──────────────── VNet: 10.10.0.0/16 ────────────────┐
│                                                     │
│  ┌──────────── Web Subnet: 10.10.1.0/24 ────────┐ │
│  │  [Web NSG]                                    │ │
│  │   ✅ 인터넷 → 80 (HTTP) 허용                  │ │
│  │   ❌ 기타 모두 차단                           │ │
│  │                                               │ │
│  │  ┌───────────────────────┐                   │ │
│  │  │  Web VM               │                   │ │
│  │  │  Public IP: x.x.x.x   │                   │ │
│  │  │  Private IP: 10.10.1.x│                   │ │
│  │  └───────────────────────┘                   │ │
│  └───────────────────────────────────────────────┘ │
│                        ↓ 8080                       │
│  ┌──────────── App Subnet: 10.10.2.0/24 ────────┐ │
│  │  [App NSG]                                    │ │
│  │   ✅ Web Subnet → 8080 허용                   │ │
│  │   ❌ 인터넷 직접 접근 차단                    │ │
│  │                                               │ │
│  │  ┌───────────────────────┐                   │ │
│  │  │  App VM               │                   │ │
│  │  │  Private IP: 10.10.2.x│                   │ │
│  │  └───────────────────────┘                   │ │
│  └───────────────────────────────────────────────┘ │
│                        ↓ 3306                       │
│  ┌──────────── DB Subnet: 10.10.3.0/24 ─────────┐ │
│  │  [DB NSG]                                     │ │
│  │   ✅ App Subnet → 3306 허용                   │ │
│  │   ❌ Web/인터넷 직접 접근 차단                │ │
│  │                                               │ │
│  │  ┌───────────────────────┐                   │ │
│  │  │  DB VM                │                   │ │
│  │  │  Private IP: 10.10.3.x│                   │ │
│  │  └───────────────────────┘                   │ │
│  └───────────────────────────────────────────────┘ │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### 2.2 보안 규칙 요약

| 출발지 | 목적지 | 포트 | 프로토콜 | 허용 여부 |
|--------|--------|------|----------|-----------|
| **인터넷** | Web | 80 | TCP | ✅ 허용 |
| **인터넷** | App | 8080 | TCP | ❌ 차단 |
| **인터넷** | DB | 3306 | TCP | ❌ 차단 |
| **Web (10.10.1.0/24)** | App | 8080 | TCP | ✅ 허용 |
| **Web** | DB | 3306 | TCP | ❌ 차단 |
| **App (10.10.2.0/24)** | DB | 3306 | TCP | ✅ 허용 |

---

## 3. Terraform 코드 분석 🔍

### 3.1 파일 구조

```
4-3tier-architecture/
├── provider.tf        # 프로바이더 설정
├── variables.tf       # 변수 선언 ⭐ NEW!
└── main.tf           # 모든 리소스 (260줄)
```

### 3.2 Variables 활용 (새로운 개념!)

#### variables.tf

```hcl
variable "location" {
  default = "koreacentral"
}

variable "resource_group_name" {
  default = "3tier-architecture-rg"
}
```

**변수의 장점**:
- ✅ 재사용성: 여러 곳에서 `var.location` 사용
- ✅ 유지보수: 한 곳만 수정하면 전체 적용
- ✅ 환경별 설정: `terraform apply -var="location=eastus"`

#### main.tf에서 사용

```hcl
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name    # 변수 참조!
  location = var.location               # 변수 참조!
}
```

### 3.3 코드 단계별 분석

#### Step 1: 기본 네트워크 인프라

```hcl
# 리소스 그룹
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# VNet
resource "azurerm_virtual_network" "vnet" {
  name                = "3tier-architecture-vnet"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# 3개의 Subnet
resource "azurerm_subnet" "web" {
  name                 = "web-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_subnet" "app" {
  name                 = "app-subnet"
  address_prefixes     = ["10.10.2.0/24"]
  # ...
}

resource "azurerm_subnet" "db" {
  name                 = "db-subnet"
  address_prefixes     = ["10.10.3.0/24"]
  # ...
}
```

**네트워크 계층**:
```
10.10.0.0/16 (VNet)
├── 10.10.1.0/24 (Web Subnet)
├── 10.10.2.0/24 (App Subnet)
└── 10.10.3.0/24 (DB Subnet)
```

#### Step 2: Web 계층 (인터넷 노출)

```hcl
# 1. NSG 생성
resource "azurerm_network_security_group" "web_nsg" {
  name                = "web-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# 2. HTTP 허용 규칙
resource "azurerm_network_security_rule" "web_http" {
  name                        = "allow-http"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"              # 모든 인터넷에서
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.web_nsg.name
}

# 3. NSG를 Subnet에 연결
resource "azurerm_subnet_network_security_group_association" "web_assoc" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.web_nsg.id
}

# 4. Public IP 생성
resource "azurerm_public_ip" "web_pip" {
  name                = "web-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"                 # 고정 IP
}

# 5. NIC (Network Interface Card) 생성
resource "azurerm_network_interface" "web_nic" {
  name                = "web-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"    # Private IP 자동 할당
    public_ip_address_id          = azurerm_public_ip.web_pip.id  # Public IP 연결!
  }
}

# 6. VM 생성
resource "azurerm_linux_virtual_machine" "web_vm" {
  name                = "web-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"           # 1 vCPU, 1GB RAM (저렴)
  admin_username      = "azureuser"
  admin_password      = "Password1234!"
  disable_password_authentication = false        # 비밀번호 인증 사용

  network_interface_ids = [
    azurerm_network_interface.web_nic.id         # NIC 연결
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"        # 표준 HDD
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"                         # Ubuntu 22.04 LTS
  }
}
```

**Web 계층 의존성 체인**:
```
azurerm_subnet.web
    ↓
azurerm_network_security_group.web_nsg
    ↓
azurerm_network_security_rule.web_http
    ↓
azurerm_subnet_network_security_group_association.web_assoc
    ↓
azurerm_public_ip.web_pip
    ↓
azurerm_network_interface.web_nic
    ↓
azurerm_linux_virtual_machine.web_vm
```

#### Step 3: App 계층 (Private)

```hcl
# 1. NSG 생성
resource "azurerm_network_security_group" "app_nsg" {
  name                = "app-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# 2. Web → App 8080 허용
resource "azurerm_network_security_rule" "app_allow_web" {
  name                        = "allow-web-8080"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "8080"
  source_address_prefix       = "10.10.1.0/24"   # ⭐ Web Subnet만!
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.app_nsg.name
}

# 3. NSG 연결
resource "azurerm_subnet_network_security_group_association" "app_assoc" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app_nsg.id
}

# 4. NIC 생성 (Public IP 없음!)
resource "azurerm_network_interface" "app_nic" {
  name                = "app-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.app.id
    private_ip_address_allocation = "Dynamic"
    # public_ip_address_id 없음 → Private만!
  }
}

# 5. VM 생성
resource "azurerm_linux_virtual_machine" "app_vm" {
  name                = "app-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  admin_password      = "Password1234!"
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.app_nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
```

**핵심 차이점**:
- ❌ Public IP 없음
- ✅ NSG에서 Web Subnet (10.10.1.0/24)만 허용
- ✅ 인터넷 직접 접근 불가

#### Step 4: DB 계층 (Private + 최고 보안)

```hcl
# 1. NSG 생성
resource "azurerm_network_security_group" "db_nsg" {
  name                = "db-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# 2. App → DB 3306 허용
resource "azurerm_network_security_rule" "db_allow_app" {
  name                        = "allow-app-3306"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3306"          # MySQL 포트
  source_address_prefix       = "10.10.2.0/24"  # ⭐ App Subnet만!
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.db_nsg.name
}

# 3. NSG 연결
resource "azurerm_subnet_network_security_group_association" "db_assoc" {
  subnet_id                 = azurerm_subnet.db.id
  network_security_group_id = azurerm_network_security_group.db_nsg.id
}

# 4. NIC 생성 (Private만)
resource "azurerm_network_interface" "db_nic" {
  name                = "db-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.db.id
    private_ip_address_allocation = "Dynamic"
  }
}

# 5. VM 생성
resource "azurerm_linux_virtual_machine" "db_vm" {
  name                = "db-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  admin_password      = "Password1234!"
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.db_nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
```

**최고 수준 보안**:
- ❌ Public IP 없음
- ✅ App Subnet (10.10.2.0/24)만 허용
- ✅ Web이나 인터넷에서 직접 접근 불가
- ✅ 데이터베이스 포트만 개방 (3306)

---

## 4. 새로운 Terraform 개념 🎓

### 4.1 Public IP (공인 IP)

```hcl
resource "azurerm_public_ip" "web_pip" {
  name                = "web-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"      # 또는 "Dynamic"
}
```

#### Allocation Method

| 방식 | 설명 | 사용 시점 |
|------|------|----------|
| **Static** | 고정 IP (VM 재시작해도 유지) | 프로덕션 웹서버 |
| **Dynamic** | IP 변경 가능 (VM 중지 시 해제) | 개발/테스트 환경 |

### 4.2 Network Interface (NIC)

**NIC는 VM과 네트워크를 연결하는 가상 네트워크 카드**입니다.

```hcl
resource "azurerm_network_interface" "web_nic" {
  name                = "web-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web.id            # 어떤 Subnet?
    private_ip_address_allocation = "Dynamic"                        # Private IP
    public_ip_address_id          = azurerm_public_ip.web_pip.id   # Public IP (선택)
  }
}
```

**역할**:
- Subnet에 연결
- Private IP 할당
- Public IP 연결 (선택)
- NSG 규칙 적용받음

### 4.3 Virtual Machine

```hcl
resource "azurerm_linux_virtual_machine" "web_vm" {
  name                = "web-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"           # VM 크기
  admin_username      = "azureuser"
  admin_password      = "Password1234!"
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.web_nic.id         # NIC 연결
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
```

#### VM Size (크기)

| Size | vCPU | RAM | 월 비용 (대략) | 용도 |
|------|------|-----|---------------|------|
| **Standard_B1s** | 1 | 1GB | ~$7 | 테스트, 경량 앱 |
| **Standard_B2s** | 2 | 4GB | ~$40 | 개발 서버 |
| **Standard_D2s_v3** | 2 | 8GB | ~$100 | 프로덕션 웹서버 |
| **Standard_D4s_v3** | 4 | 16GB | ~$200 | 대규모 애플리케이션 |

#### OS Disk Type

| Type | 설명 | IOPS | 가격 |
|------|------|------|------|
| **Standard_LRS** | 표준 HDD | ~500 | 저렴 |
| **StandardSSD_LRS** | 표준 SSD | ~6,000 | 중간 |
| **Premium_LRS** | 프리미엄 SSD | ~5,000-20,000 | 비쌈 |

#### 인증 방식

```hcl
# 방법 1: 비밀번호 (간편하지만 덜 안전)
admin_username      = "azureuser"
admin_password      = "Password1234!"
disable_password_authentication = false

# 방법 2: SSH 키 (권장, 더 안전)
admin_username      = "azureuser"
disable_password_authentication = true
admin_ssh_key {
  username   = "azureuser"
  public_key = file("~/.ssh/id_rsa.pub")
}
```

---

## 5. 실습 및 검증 🚀

### 5.1 배포하기

```bash
# 1. 초기화
terraform init

# 2. 계획 확인
terraform plan
```

**예상 출력**:
```
Plan: 21 to add, 0 to change, 0 to destroy.
```

**21개 리소스**:
- 1 Resource Group
- 1 VNet
- 3 Subnets
- 3 NSGs
- 3 NSG Rules
- 3 NSG Associations
- 1 Public IP
- 3 NICs
- 3 VMs

```bash
# 3. 적용 (5-10분 소요)
terraform apply
```

### 5.2 생성된 리소스 확인

```bash
# 모든 리소스 목록
terraform state list
```

**출력 예시**:
```
azurerm_resource_group.rg
azurerm_virtual_network.vnet
azurerm_subnet.web
azurerm_subnet.app
azurerm_subnet.db
azurerm_network_security_group.web_nsg
azurerm_network_security_group.app_nsg
azurerm_network_security_group.db_nsg
azurerm_network_security_rule.web_http
azurerm_network_security_rule.app_allow_web
azurerm_network_security_rule.db_allow_app
azurerm_subnet_network_security_group_association.web_assoc
azurerm_subnet_network_security_group_association.app_assoc
azurerm_subnet_network_security_group_association.db_assoc
azurerm_public_ip.web_pip
azurerm_network_interface.web_nic
azurerm_network_interface.app_nic
azurerm_network_interface.db_nic
azurerm_linux_virtual_machine.web_vm
azurerm_linux_virtual_machine.app_vm
azurerm_linux_virtual_machine.db_vm
```

### 5.3 Public IP 확인

```bash
# Web VM의 Public IP 확인
terraform state show azurerm_public_ip.web_pip | grep ip_address
```

**또는 Azure CLI**:
```bash
az network public-ip show \
  --name web-pip \
  --resource-group 3tier-architecture-rg \
  --query ipAddress -o tsv
```

**출력 예시**:
```
20.196.123.45
```

### 5.4 접속 테스트

#### Web VM 접속 (Public IP)

```bash
# SSH 접속
ssh azureuser@20.196.123.45

# 비밀번호: Password1234!
```

**성공 시**:
```
Welcome to Ubuntu 22.04 LTS
azureuser@web-vm:~$
```

#### App/DB VM 접속 시도 (실패해야 정상)

```bash
# App VM 접속 시도 (Private IP만 있음)
ssh azureuser@10.10.2.x

# 예상 결과: 타임아웃 (Public IP 없어서 접근 불가)
```

### 5.5 네트워크 연결성 테스트

**Web VM에서 테스트** (Web VM에 SSH 접속 후):

```bash
# 1. App VM에 접속 가능? (Private IP)
ping 10.10.2.x

# 2. App 포트(8080) 열려있나?
nc -zv 10.10.2.x 8080

# 3. DB VM에 직접 접속 가능? (차단되어야 함)
nc -zv 10.10.3.x 3306
# 예상: Connection timed out (NSG에서 차단)
```

**네트워크 흐름 확인**:
```
✅ Web → App (8080): 허용
❌ Web → DB (3306): 차단 (NSG 규칙 없음)
```

---

## 6. 실무 개선 사항 🎯

### 6.1 Output 추가하기

**outputs.tf 파일 생성** (권장):

```hcl
output "web_public_ip" {
  description = "Web VM의 Public IP 주소"
  value       = azurerm_public_ip.web_pip.ip_address
}

output "web_vm_id" {
  description = "Web VM의 Azure Resource ID"
  value       = azurerm_linux_virtual_machine.web_vm.id
}

output "app_private_ip" {
  description = "App VM의 Private IP 주소"
  value       = azurerm_network_interface.app_nic.private_ip_address
}

output "db_private_ip" {
  description = "DB VM의 Private IP 주소"
  value       = azurerm_network_interface.db_nic.private_ip_address
}

output "resource_group_name" {
  description = "리소스 그룹 이름"
  value       = azurerm_resource_group.rg.name
}
```

**사용**:
```bash
terraform apply

# 출력 자동 표시
Outputs:

web_public_ip       = "20.196.123.45"
app_private_ip      = "10.10.2.4"
db_private_ip       = "10.10.3.4"
resource_group_name = "3tier-architecture-rg"
```

### 6.2 Variables 확장

**variables.tf 개선**:

```hcl
variable "location" {
  description = "Azure 리전"
  type        = string
  default     = "koreacentral"
}

variable "resource_group_name" {
  description = "리소스 그룹 이름"
  type        = string
  default     = "3tier-architecture-rg"
}

variable "vm_size" {
  description = "VM 크기"
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "VM 관리자 사용자명"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "VM 관리자 비밀번호"
  type        = string
  sensitive   = true
  default     = "Password1234!"
}

variable "vnet_address_space" {
  description = "VNet 주소 공간"
  type        = list(string)
  default     = ["10.10.0.0/16"]
}

variable "subnet_prefixes" {
  description = "각 Subnet의 주소 범위"
  type = object({
    web = string
    app = string
    db  = string
  })
  default = {
    web = "10.10.1.0/24"
    app = "10.10.2.0/24"
    db  = "10.10.3.0/24"
  }
}

variable "allowed_ports" {
  description = "각 계층별 허용 포트"
  type = object({
    web = number
    app = number
    db  = number
  })
  default = {
    web = 80
    app = 8080
    db  = 3306
  }
}
```

**main.tf에서 사용**:

```hcl
resource "azurerm_subnet" "web" {
  name             = "web-subnet"
  address_prefixes = [var.subnet_prefixes.web]  # 변수 사용
  # ...
}

resource "azurerm_network_security_rule" "web_http" {
  destination_port_range = var.allowed_ports.web  # 변수 사용
  # ...
}

resource "azurerm_linux_virtual_machine" "web_vm" {
  size           = var.vm_size           # 변수 사용
  admin_username = var.admin_username    # 변수 사용
  admin_password = var.admin_password    # 변수 사용
  # ...
}
```

### 6.3 환경별 설정 파일

**terraform.tfvars** (기본값):
```hcl
location            = "koreacentral"
resource_group_name = "3tier-dev-rg"
vm_size             = "Standard_B1s"
```

**prod.tfvars** (프로덕션):
```hcl
location            = "koreacentral"
resource_group_name = "3tier-prod-rg"
vm_size             = "Standard_D2s_v3"           # 더 큰 VM
admin_password      = "SuperSecurePassword123!"  # 다른 비밀번호

subnet_prefixes = {
  web = "10.20.1.0/24"  # 다른 IP 대역
  app = "10.20.2.0/24"
  db  = "10.20.3.0/24"
}
```

**사용**:
```bash
# 개발 환경
terraform apply

# 프로덕션 환경
terraform apply -var-file="prod.tfvars"
```

### 6.4 Tags 추가

```hcl
variable "common_tags" {
  description = "모든 리소스에 적용할 태그"
  type        = map(string)
  default = {
    Environment = "Development"
    Project     = "3-Tier-Demo"
    ManagedBy   = "Terraform"
    CostCenter  = "Engineering"
  }
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.common_tags              # 태그 적용
}

resource "azurerm_linux_virtual_machine" "web_vm" {
  name     = "web-vm"
  # ...
  tags = merge(
    var.common_tags,
    {
      Tier = "Web"                        # 계층별 추가 태그
      Role = "Frontend"
    }
  )
}
```

---

## 7. 보안 강화 방안 🔒

### 7.1 Bastion Host 추가

**문제**: App/DB VM에 SSH 접속이 불가능합니다 (Public IP 없음).

**해결**: Bastion Host (점프 서버) 사용

```hcl
# Management Subnet 추가
resource "azurerm_subnet" "mgmt" {
  name             = "mgmt-subnet"
  address_prefixes = ["10.10.10.0/24"]
  # ...
}

# Bastion VM 생성 (Public IP 있음)
resource "azurerm_linux_virtual_machine" "bastion_vm" {
  name = "bastion-vm"
  # ... Public IP 연결
}
```

**사용 방법**:
```bash
# 1. Bastion에 접속
ssh azureuser@bastion-public-ip

# 2. Bastion에서 App VM에 접속
ssh azureuser@10.10.2.x
```

### 7.2 SSH 키 인증으로 변경

```hcl
resource "azurerm_linux_virtual_machine" "web_vm" {
  # ...
  admin_username                  = "azureuser"
  disable_password_authentication = true  # 비밀번호 비활성화

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")  # SSH 공개키 사용
  }
}
```

### 7.3 Key Vault 통합

```hcl
# Key Vault에서 비밀번호 가져오기
data "azurerm_key_vault_secret" "vm_password" {
  name         = "vm-admin-password"
  key_vault_id = azurerm_key_vault.main.id
}

resource "azurerm_linux_virtual_machine" "web_vm" {
  # ...
  admin_password = data.azurerm_key_vault_secret.vm_password.value
}
```

### 7.4 NSG 규칙 강화

```hcl
# SSH를 특정 IP에서만 허용
resource "azurerm_network_security_rule" "web_ssh" {
  name                       = "allow-ssh-admin"
  priority                   = 110
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  destination_port_range     = "22"
  source_address_prefix      = "203.0.113.10/32"  # 관리자 IP만
  destination_address_prefix = "*"
  # ...
}

# RDP 완전 차단
resource "azurerm_network_security_rule" "deny_rdp" {
  name                       = "deny-rdp"
  priority                   = 120
  direction                  = "Inbound"
  access                     = "Deny"
  protocol                   = "Tcp"
  destination_port_range     = "3389"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  # ...
}
```

---

## 8. 비용 최적화 💰

### 8.1 현재 구성의 월 예상 비용

| 리소스 | 수량 | 단가 | 월 비용 |
|--------|------|------|---------|
| VM (Standard_B1s) | 3대 | $7 | $21 |
| Public IP (Static) | 1개 | $3 | $3 |
| Disk (Standard_LRS 30GB) | 3개 | $2 | $6 |
| VNet | 1개 | 무료 | $0 |
| NSG | 3개 | 무료 | $0 |
| **총계** | - | - | **~$30** |

### 8.2 비용 절감 팁

**1. VM 자동 종료**
```bash
# 개발 시간 외에는 VM 자동 종료 (Azure Portal 설정)
# 또는 Azure Automation 사용
```

**2. Reserved Instances**
```
1년 예약: 30% 절약
3년 예약: 50% 절약
```

**3. Spot Instances**
```hcl
resource "azurerm_linux_virtual_machine" "web_vm" {
  # ...
  priority        = "Spot"
  eviction_policy = "Deallocate"
  max_bid_price   = 0.02  # 시간당 최대 $0.02
}
```

**4. Dynamic Public IP** (개발 환경)
```hcl
resource "azurerm_public_ip" "web_pip" {
  allocation_method = "Dynamic"  # Static 대신
}
# 절약: $3/월
```

---

## 9. 트러블슈팅 🔧

### 9.1 VM 생성 실패

**오류**:
```
Error: creating Linux Virtual Machine: authorization failed
```

**원인**: Azure 구독 권한 부족

**해결**:
```bash
# Azure CLI로 로그인 확인
az login
az account show
```

### 9.2 SSH 접속 안 됨

**증상**: `ssh: connect to host x.x.x.x port 22: Connection timed out`

**체크리스트**:
1. NSG에 SSH 규칙 있나?
2. VM이 실행 중인가?
3. Public IP가 올바른가?

**해결**:
```hcl
# SSH 규칙 추가
resource "azurerm_network_security_rule" "web_ssh" {
  name                   = "allow-ssh"
  priority               = 110
  destination_port_range = "22"
  # ...
}
```

### 9.3 비용 폭탄 방지

**문제**: `terraform apply` 후 비용이 예상보다 높음

**원인**: VM이 계속 실행 중

**해결**:
```bash
# 사용 안 할 때는 중지
az vm stop --name web-vm --resource-group 3tier-architecture-rg
az vm deallocate --name web-vm --resource-group 3tier-architecture-rg

# 또는 완전 삭제
terraform destroy
```

---

## 10. 학습 체크리스트 ✅

### 필수 개념
- [ ] 3-Tier 아키텍처의 각 계층 역할 이해
- [ ] Public vs Private IP 차이
- [ ] NIC(Network Interface)의 역할
- [ ] VM Size와 OS Disk Type 선택 기준
- [ ] Variables를 활용한 코드 재사용
- [ ] NSG 규칙으로 계층 간 통신 제어

### 실습 완료
- [ ] 전체 아키텍처 배포
- [ ] Web VM에 SSH 접속
- [ ] Public IP 확인
- [ ] NSG 규칙 검증
- [ ] Output으로 정보 추출
- [ ] Resources 정리 (destroy)

### 심화
- [ ] Variables를 파일로 분리
- [ ] 환경별 tfvars 작성
- [ ] Tags로 리소스 분류
- [ ] SSH 키 인증 적용
- [ ] Bastion Host 개념 이해

---

## 🎓 선생님의 마무리 조언

### 이번 폴더에서 배운 것

1. **완전한 3-Tier 아키텍처 구현**
   - Web (Public) → App (Private) → DB (Private)
   - 계층별 보안 규칙
   - VM, NIC, Public IP 생성

2. **Variables 활용**
   - 재사용 가능한 코드
   - 환경별 설정 분리
   - 유지보수성 향상

3. **실무 패턴**
   - 보안 계층화
   - 최소 권한 원칙
   - 비용 최적화

### 다음 단계

이제 여러분은:
- ✅ Terraform 기본 문법 마스터
- ✅ Azure 네트워크 설계 가능
- ✅ 3-Tier 아키텍처 구축 가능
- ✅ 보안 규칙 작성 가능

**다음 학습 주제**:
1. **Modules** - 코드 재사용과 패키지화
2. **Remote State** - 팀 협업
3. **Load Balancer** - 고가용성
4. **Auto Scaling** - 자동 확장
5. **CI/CD 통합** - 자동 배포

### 실무 프로젝트 아이디어

직접 만들어보세요:

```
프로젝트 1: 블로그 시스템
- Web: Nginx + Static Files
- App: Node.js + Express
- DB: PostgreSQL

프로젝트 2: E-commerce
- Web: React 빌드 파일
- App: Spring Boot API
- DB: MySQL

프로젝트 3: 모니터링 시스템
- Web: Grafana
- App: Prometheus
- DB: InfluxDB
```

---

**축하합니다!** 🎉 완전한 클라우드 인프라를 코드로 구축했습니다. 이제 진짜 DevOps 엔지니어의 길을 걷고 있습니다! 🚀
