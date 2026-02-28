# Terraform 모듈 생성 및 연결 관계 완벽 가이드

## 📖 개요

이 문서는 Terraform에서 모듈을 만들고, 여러 모듈을 함께 사용하면서 데이터를 주고받는 방법을 설명합니다. "모듈 간 의존성"을 이해하는 것이 가장 중요합니다.

---

## 🎯 핵심 개념

### 모듈이란?

**모듈 = 재사용 가능한 Terraform 코드 패키지**

```
┌─────────────────────────────────┐
│      Module (폴더)              │
├─────────────────────────────────┤
│ variables.tf  (입력값)          │
│ main.tf       (리소스 정의)     │
│ outputs.tf    (출력값)          │
└─────────────────────────────────┘
```

### 모듈의 세 가지 파일

| 파일 | 역할 | 유사성 |
|------|------|--------|
| **variables.tf** | 모듈이 받을 입력값 정의 | 함수의 매개변수 |
| **main.tf** | 실제 리소스 정의 | 함수의 본문 |
| **outputs.tf** | 모듈이 반환하는 값 | 함수의 반환값 |

### 모듈 호출이란?

**모듈 호출 = 함수 호출과 동일한 개념**

```hcl
# 함수 호출과 비교
# 프로그래밍: result = add(a=5, b=3)
# Terraform: module "example" { a = 5; b = 3 }
```

---

## 🏗️ 우리 프로젝트의 모듈 구조

### 파일 트리

```
6-vmss-lb/
├── modules/
│   ├── network/              ← 네트워크 모듈
│   │   ├── main.tf          (VPC, 서브넷 생성)
│   │   ├── variables.tf      (입력: 이름, CIDR 등)
│   │   └── outputs.tf        (출력: 서브넷 ID 등)
│   │
│   ├── nsg/                  ← 보안 그룹 모듈
│   │   ├── main.tf          (NSG 규칙 생성)
│   │   ├── variables.tf      (입력: 서브넷 ID 등)
│   │   └── outputs.tf        (출력: NSG ID 등)
│   │
│   └── loadbalancer/         ← 로드밸런서 모듈
│       ├── main.tf          (LB 리소스 생성)
│       ├── variables.tf      (입력: 서브넷 ID 등)
│       └── outputs.tf        (출력: LB 정보)
│
└── environments/dev/
    ├── main.tf              ← 모듈 호출 장소
    ├── variables.tf
    ├── terraform.tfvars
    └── backend.tf
```

---

## 🔗 모듈 간 의존성 흐름도

```
environments/dev/main.tf (모듈 조정자)
    │
    ├─→ module "network"      (1단계: 네트워크 기본 구성)
    │   └─ outputs: web_subnet_id, resource_group_name
    │       │
    │       ├──→ module "nsg" (2단계: 보안 규칙 적용)
    │       │    inputs: web_subnet_id 사용
    │       │
    │       └──→ module "loadbalancer" (2단계: 트래픽 분산)
    │            inputs: 웹 서브넷 ID 사용
    │
    └─→ (NSG와 LoadBalancer는 network 결과에 의존)
```

### 시간 순서로 보기

```
시간 흐름 →

1️⃣ network 모듈 실행
   ↓ (완료 후)
   VPC, 서브넷, 리소스 그룹 생성 ✓

2️⃣ network의 출력값(outputs)을 다른 모듈에 입력
   nsg와 loadbalancer가 network 결과를 활용

3️⃣ nsg와 loadbalancer 모듈 실행
   (network 모듈이 완료되었으므로 필요한 데이터 사용 가능)
```

---

## 📝 단계별 상세 분석

### Step 1: network 모듈 정의

#### network 모듈의 입력값 (variables.tf)

```hcl
# modules/network/variables.tf
variable "resource_group_name" {}      ← 리소스 그룹 이름
variable "location" {}                 ← Azure 지역
variable "vnet_name" {}                ← VPC 이름
variable "vnet_cidr" {}                ← VPC IP 범위
variable "web_subnet_cidr" {}          ← 웹 서브넷 IP 범위
variable "db_subnet_cidr" {}           ← DB 서브넷 IP 범위
```

**의미**: "이 모듈은 6개의 정보를 입력받아서 사용합니다"

#### network 모듈의 리소스 (main.tf)

```hcl
# modules/network/main.tf
resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [var.vnet_cidr]
}

resource "azurerm_subnet" "web" {
  name                 = "web-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.web_subnet_cidr]
}

resource "azurerm_subnet" "db" {
  name                 = "db-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.db_subnet_cidr]
}
```

**의미**: "입력받은 정보를 사용해서 VPC와 서브넷을 만듭니다"

#### network 모듈의 출력값 (outputs.tf)

```hcl
# modules/network/outputs.tf (예상 내용)
output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "web_subnet_id" {
  value = azurerm_subnet.web.id
}

output "db_subnet_id" {
  value = azurerm_subnet.db.id
}

output "vnet_id" {
  value = azurerm_virtual_network.this.id
}
```

**의미**: "이 모듈이 생성한 중요한 정보들을 다른 모듈이 사용할 수 있도록 제공합니다"

---

### Step 2: nsg 모듈 정의

#### nsg 모듈의 입력값 (variables.tf)

```hcl
# modules/nsg/variables.tf
variable "resource_group_name" {}      ← network 모듈의 출력값 받음
variable "location" {}
variable "web_subnet_id" {}            ← network 모듈의 출력값 받음
variable "db_subnet_id" {}             ← network 모듈의 출력값 받음
variable "web_subnet_cidr" {}
```

**의미**: "이 모듈은 network 모듈이 만든 서브넷들의 ID를 입력받습니다"

#### nsg 모듈의 리소스 (main.tf)

```hcl
# modules/nsg/main.tf (예상 내용)
resource "azurerm_network_security_group" "web" {
  name                = "web-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  # 보안 규칙들...
}

resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = var.web_subnet_id  ← network 모듈의 출력값
  network_security_group_id = azurerm_network_security_group.web.id
}
```

**의미**: "network에서 받은 서브넷에 보안 규칙을 적용합니다"

---

### Step 3: environments/dev/main.tf에서 모듈 호출

```hcl
# environments/dev/main.tf
provider "azurerm" {
  features {}
}

# 1️⃣ 첫 번째: network 모듈 호출
module "network" {
  source = "../../modules/network"

  # 입력값 제공
  resource_group_name = "dev-rg"
  location            = "Korea Central"
  vnet_name           = "dev-vnet"
  vnet_cidr           = "10.10.0.0/16"
  web_subnet_cidr     = "10.10.1.0/24"
  db_subnet_cidr      = "10.10.2.0/24"
}

# 2️⃣ 두 번째: nsg 모듈 호출 (network 결과 사용)
module "nsg" {
  source = "../../modules/nsg"

  # network 모듈의 출력값을 입력값으로 사용!
  resource_group_name = module.network.resource_group_name
  location            = "Korea Central"
  web_subnet_id       = module.network.web_subnet_id       # ← 의존성!
  db_subnet_id        = module.network.db_subnet_id        # ← 의존성!
  web_subnet_cidr     = "10.10.1.0/24"
}

# 3️⃣ 세 번째: loadbalancer 모듈 호출 (network 결과 사용)
module "loadbalancer" {
  source = "../../modules/loadbalancer"

  resource_group_name = module.network.resource_group_name
  location            = "Korea Central"
  backend_subnet_id   = module.network.web_subnet_id       # ← 의존성!
}
```

**핵심 구문**: `module.network.web_subnet_id`
- `module.network` = network라는 이름으로 호출된 모듈
- `.web_subnet_id` = 그 모듈의 출력값

---

## 🔄 의존성 해석하기

### 의존성이란?

```
"A 모듈은 B 모듈의 결과가 필요하다"
↓
"따라서 B를 먼저 실행한 후 A를 실행한다"
```

### 코드로 표현

```hcl
# 명시적 의존성
module "nsg" {
  resource_group_name = module.network.resource_group_name  ← 이 줄이 의존성 선언!
  web_subnet_id       = module.network.web_subnet_id
}
```

**Terraform이 인식하는 것**:
1. `nsg` 모듈은 `network` 모듈의 출력값을 필요로 한다
2. 따라서 `network`를 먼저 완료해야 한다
3. `network` 완료 → `nsg` 시작

---

## 📊 모듈 간 데이터 흐름

```
environments/dev/main.tf
├─ module "network" 호출
│  ├─ 입력: resource_group_name = "dev-rg"
│  ├─ 실행: VPC, 서브넷 생성
│  └─ 출력:
│     ├─ resource_group_name = "dev-rg"
│     ├─ web_subnet_id = "/subscriptions/.../subnets/web-subnet"
│     └─ db_subnet_id = "/subscriptions/.../subnets/db-subnet"
│
├─ module "nsg" 호출
│  ├─ 입력:
│  │  ├─ resource_group_name = module.network.resource_group_name ← 위에서 받음
│  │  ├─ web_subnet_id = module.network.web_subnet_id ← 위에서 받음
│  │  └─ db_subnet_id = module.network.db_subnet_id ← 위에서 받음
│  ├─ 실행: 보안 규칙 생성 및 적용
│  └─ 출력: (생략)
│
└─ module "loadbalancer" 호출
   ├─ 입력:
   │  ├─ resource_group_name = module.network.resource_group_name ← 위에서 받음
   │  └─ backend_subnet_id = module.network.web_subnet_id ← 위에서 받음
   ├─ 실행: 로드밸런서 생성
   └─ 출력: (생략)
```

---

## ✅ 모듈 생성 체크리스트

새로운 모듈을 만들 때 다음을 확인하세요:

### 모듈 폴더 구조
- [ ] `modules/[모듈명]/` 폴더 생성
- [ ] `variables.tf` 파일 생성
- [ ] `main.tf` 파일 생성
- [ ] `outputs.tf` 파일 생성

### variables.tf 작성
- [ ] 필요한 모든 입력값을 변수로 정의
- [ ] 각 변수에 적절한 type 지정 (string, list, map 등)
- [ ] 모듈 내에서만 사용되는 변수인지 확인
- [ ] 기본값은 설정하지 않거나 최소한으로 유지

### main.tf 작성
- [ ] 변수값을 `var.변수명`으로 참조
- [ ] 리소스 이름에 `this`를 사용 (예: `azurerm_resource_group.this`)

### outputs.tf 작성
- [ ] 다른 모듈이 필요로 할 만한 정보 출력
- [ ] 리소스의 ID, 이름, IP 등 식별 정보 포함
- [ ] 출력값에 description 추가

### 모듈 호출
- [ ] `source` 경로가 올바른지 확인
- [ ] 모든 필수 입력값을 제공했는지 확인
- [ ] 다른 모듈의 출력값을 정확히 참조했는지 확인

---

## 🚨 자주 하는 실수

### ❌ 실수 1: 출력값을 정의하지 않음

```hcl
# 나쁜 예: outputs.tf가 없음
# modules/network/
# ├── main.tf
# └── variables.tf

# main.tf에서 nsg 모듈 호출 시 오류!
module "nsg" {
  web_subnet_id = module.network.web_subnet_id  # 이 값이 없음!
}
```

**해결책**: `outputs.tf`를 작성하여 필요한 값을 출력

```hcl
# modules/network/outputs.tf
output "web_subnet_id" {
  value = azurerm_subnet.web.id
}
```

### ❌ 실수 2: 순환 의존성 (Circular Dependency)

```hcl
# 나쁜 예
module "a" {
  input = module.b.output  # B의 출력 필요
}

module "b" {
  input = module.a.output  # A의 출력 필요 ← 무한 루프!
}
```

**해결책**: 의존성 구조를 다시 설계하여 한 방향으로 흐르게 정렬

### ❌ 실수 3: 모듈 내 하드코딩

```hcl
# 나쁜 예
# modules/network/main.tf
resource "azurerm_virtual_network" "this" {
  name                = "hard-coded-vnet"    # 하드코딩!
  address_space       = ["10.10.0.0/16"]     # 하드코딩!
}
```

**해결책**: 변수를 사용하여 유연하게

```hcl
# 좋은 예
variable "vnet_name" {}
variable "vnet_cidr" {}

resource "azurerm_virtual_network" "this" {
  name          = var.vnet_name
  address_space = [var.vnet_cidr]
}
```

---

## 📝 실습 예제

### 새로운 모듈 추가하기: "compute" 모듈

**목표**: VM 스케일 세트를 만드는 모듈 추가

#### Step 1: 폴더 생성
```bash
mkdir -p modules/compute
cd modules/compute
```

#### Step 2: variables.tf 작성
```hcl
# modules/compute/variables.tf
variable "resource_group_name" {}
variable "location" {}
variable "subnet_id" {}  # network 모듈의 출력값
variable "vmss_name" {}
variable "instance_count" {}
```

#### Step 3: main.tf 작성
```hcl
# modules/compute/main.tf
resource "azurerm_windows_virtual_machine_scale_set" "this" {
  name                        = var.vmss_name
  resource_group_name         = var.resource_group_name
  location                    = var.location
  instances                   = var.instance_count
  sku                         = "Standard_B2s"

  network_interface {
    primary       = true
    subnet_id     = var.subnet_id  # network 모듈의 출력값 사용
  }

  # 기타 설정...
}
```

#### Step 4: outputs.tf 작성
```hcl
# modules/compute/outputs.tf
output "vmss_id" {
  value = azurerm_windows_virtual_machine_scale_set.this.id
}
```

#### Step 5: main.tf에서 호출
```hcl
# environments/dev/main.tf
module "compute" {
  source = "../../modules/compute"

  resource_group_name = module.network.resource_group_name
  location            = "Korea Central"
  subnet_id           = module.network.web_subnet_id  # network의 출력값 사용!
  vmss_name           = "dev-vmss"
  instance_count      = 2
}
```

---

## 🔗 관련 파일
- [modules/network/](../../../modules/network) - 네트워크 모듈 분석
- [modules/nsg/](../../../modules/nsg) - NSG 모듈 분석
- [modules/loadbalancer/](../../../modules/loadbalancer) - 로드밸런서 모듈 분석
- [environments/dev/main.tf](../../../environments/dev/main.tf) - 모듈 호출 분석
