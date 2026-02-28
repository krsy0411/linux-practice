# Terraform 변수 완벽 가이드: variables.tf vs terraform.tfvars

## 📖 개요

Terraform에서 변수를 관리하는 것이 혼란스러울 수 있습니다. 이 문서에서는 `variables.tf`와 `terraform.tfvars`의 차이, 그리고 모듈 내에서 변수가 어떻게 작동하는지 명확히 설명합니다.

---

## 🎯 핵심 개념

Terraform의 변수 체계를 이해하려면 다음 세 가지를 구분해야 합니다:

### 1. **variables.tf**: 변수 정의 (선언)
- **역할**: "이 파일/모듈은 어떤 입력값을 받을 수 있는가?"를 정의
- **위치**: 모든 Terraform 파일이 있는 디렉토리
- **내용**: 변수 이름, 타입, 설명, 기본값 정도만 명시
- **예시**:
```hcl
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "my-rg"
}

variable "location" {
  description = "Azure region"
  type        = string
  # default가 없으면 반드시 값을 제공해야 함
}
```

### 2. **terraform.tfvars**: 변수 값 할당 (구체적 값)
- **역할**: "변수에 실제로 어떤 값을 넣을 것인가?"를 지정
- **위치**: 보통 환경별 디렉토리 (dev, prod 등)
- **내용**: 변수 이름과 실제 값의 매핑
- **예시**:
```hcl
resource_group_name = "dev-rg"
location            = "Korea Central"
```

### 3. **main.tf**: 변수 사용
- **역할**: 정의된 변수를 실제 리소스 생성에 사용
- **문법**: `var.변수이름` 형태로 참조
- **예시**:
```hcl
resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
}
```

---

## 📊 비교 표

| 항목 | variables.tf | terraform.tfvars |
|------|-------------|-----------------|
| **목적** | 변수 정의/선언 | 변수 값 할당 |
| **파일명** | 고정 (variables.tf) | 선택 (*.tfvars) |
| **내용** | type, description, default | 실제 값 |
| **필수여부** | 필수 (변수 사용 시) | 선택 (기본값이 있으면) |
| **작성 빈도** | 거의 변경 안함 | 환경마다 자주 변경 |
| **민감정보** | ❌ 포함하면 안됨 | ⚠️ .gitignore 처리 필요 |

---

## 🏗️ 우리 프로젝트 구조에서의 예시

### environments/dev/ 폴더 구조

```
environments/dev/
├── main.tf              ← 모듈 호출 (모듈에 값 전달)
├── variables.tf         ← "이 환경이 받을 수 있는 변수" 정의
├── terraform.tfvars    ← "이 환경의 실제 값" 지정
└── backend.tf           ← 상태 파일 저장소 설정
```

### 3단계로 보는 변수 흐름

#### Step 1️⃣: variables.tf에서 변수 정의
```hcl
# environments/dev/variables.tf
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region"
  type        = string
  # 기본값 없음 = 반드시 값을 제공해야 함
}
```

#### Step 2️⃣: terraform.tfvars에서 값 할당
```hcl
# environments/dev/terraform.tfvars
environment = "dev"
location    = "Korea Central"
```

#### Step 3️⃣: main.tf에서 모듈에 값 전달
```hcl
# environments/dev/main.tf
module "network" {
  source = "../../modules/network"

  # 이 값들이 모듈의 variables.tf에서 정의되어야 함
  resource_group_name = "dev-rg"
  location            = var.location    ← 변수 참조
  vnet_name           = "dev-vnet"
}
```

---

## 🧩 모듈에서의 변수 동작

### 모듈의 구조

```
modules/network/
├── main.tf           ← 리소스 정의
├── variables.tf      ← "이 모듈이 받을 수 있는 입력" 정의
└── outputs.tf        ← "이 모듈이 제공하는 출력" 정의
```

### 모듈의 variables.tf

모듈의 `variables.tf`는 **"이 모듈이 입력값으로 받을 수 있는 것"**을 정의합니다.

```hcl
# modules/network/variables.tf
variable "resource_group_name" {}    ← 아무 설명 없음 (모듈 간단히 유지)
variable "location" {}
variable "vnet_name" {}
variable "vnet_cidr" {}
variable "web_subnet_cidr" {}
variable "db_subnet_cidr" {}
```

**특징**:
- description과 default가 없는 경우가 많음 (모듈은 간단하게)
- 호출 시 반드시 모든 값을 제공해야 함
- 중복된 변수를 여러 모듈에서 받을 수 있음

### 모듈 호출 시 변수 전달

```hcl
# environments/dev/main.tf
module "network" {
  source = "../../modules/network"

  # 모듈이 요구하는 변수들을 제공
  resource_group_name = "dev-rg"
  location            = "Korea Central"
  vnet_name           = "dev-vnet"
  vnet_cidr           = "10.10.0.0/16"
  web_subnet_cidr     = "10.10.1.0/24"
  db_subnet_cidr      = "10.10.2.0/24"
}
```

---

## 💡 변수 선언 스타일 비교

### 상세한 스타일 (최상위 레벨에서 권장)
```hcl
# environments/dev/variables.tf
variable "location" {
  description = "Azure region where resources will be deployed"
  type        = string
  default     = "Korea Central"

  validation {
    condition     = contains(["Korea Central", "Korea South"], var.location)
    error_message = "Valid locations are: Korea Central, Korea South"
  }
}
```

**장점**:
- 사용자가 입력할 때 설명 참고 가능
- 유효성 검사 가능
- 누군가 새로 작업할 때 이해하기 쉬움

### 간단한 스타일 (모듈 내에서 권장)
```hcl
# modules/network/variables.tf
variable "resource_group_name" {}
variable "location" {}
```

**장점**:
- 모듈 코드가 간결함
- 호출하는 곳(main.tf)에서 의미가 명확함

---

## 🔄 변수 값을 받는 순서 (우선순위)

Terraform은 다음 순서로 변수 값을 결정합니다 (위에 있을수록 높은 우선순위):

1. **CLI 플래그**: `-var "location=Korea South"`
2. **terraform.tfvars 파일**
3. **환경변수**: `TF_VAR_location="Korea South"`
4. **변수 정의의 default 값**
5. **대화형 입력** (default가 없을 때만)

### 예시로 보는 우선순위

```bash
# terraform.tfvars에서 읽음
terraform apply
# 출력: location = "Korea Central"

# CLI 플래그가 더 우선순위 높음
terraform apply -var "location=Korea South"
# 출력: location = "Korea South"
```

---

## 🚨 자주 하는 실수

### ❌ 실수 1: 모듈에서 variables.tf에 기본값을 설정
```hcl
# 나쁜 예
variable "location" {
  type    = string
  default = "Korea Central"  ← 모듈의 기본값
}
```

**문제**: 모듈을 여러 환경에서 사용할 때 상충 가능

**올바른 방법**:
```hcl
# 좋은 예 - 모듈에서는 기본값 없음
variable "location" {
  type = string
}

# 호출하는 곳(main.tf)에서 값 명시
module "network" {
  source = "../../modules/network"
  location = "Korea Central"
}
```

### ❌ 실수 2: terraform.tfvars를 커밋하기
```bash
# 나쁜 예
git add terraform.tfvars
git commit -m "add tfvars"  ← 민감정보가 노출될 수 있음
```

**올바른 방법**:
```bash
# .gitignore에 추가
echo "terraform.tfvars" >> .gitignore

# 또는 tfvars를 예시로 제공
# terraform.tfvars.example 생성
cat > terraform.tfvars.example << EOF
location = "Korea Central"
environment = "dev"
EOF
```

### ❌ 실수 3: 모듈에서 여러 개의 변수를 반복 정의
```hcl
# 나쁜 예 - network 모듈
variable "resource_group_name" {}
variable "location" {}

# nsg 모듈
variable "resource_group_name" {}  ← 중복!
variable "location" {}              ← 중복!
```

**올바른 방법**: 각 모듈은 필요한 것만 정의하고, 호출하는 곳에서 연결
```hcl
# main.tf에서 여러 모듈에 같은 값 전달
module "network" {
  source = "../../modules/network"
  location = var.location
}

module "nsg" {
  source = "../../modules/nsg"
  location = var.location  ← 같은 변수값 재사용
}
```

---

## 📝 우리 프로젝트 실습

### 현재 구조 분석

**environments/dev/variables.tf**:
```hcl
# Backend 관련 변수 (상태 파일 저장소)
variable "backend_resource_group_name" { default = "..." }

# 환경 변수 (리소스 생성에 사용)
variable "environment" { default = "dev" }
variable "location" { default = "Korea Central" }
variable "resource_group_name" { default = "vmss-lb-rg-dev" }
```

**environments/dev/main.tf**:
```hcl
# network 모듈 호출 - 값을 직접 전달
module "network" {
  source = "../../modules/network"

  resource_group_name = "dev-rg"          ← 하드코딩
  location            = "Korea Central"   ← 하드코딩
  # ...
}
```

**개선 제안**: 모듈 호출 시 variables.tf의 변수를 참조하면 더 유연합니다.

---

## ✅ 체크리스트

Terraform 변수를 올바르게 사용하고 있는지 확인하세요:

- [ ] `variables.tf`에서는 "가능한 입력"을 정의했는가?
- [ ] `terraform.tfvars`에서는 "실제 값"을 할당했는가?
- [ ] `main.tf`에서 모듈 호출 시 필요한 모든 변수를 전달했는가?
- [ ] 모듈의 `variables.tf`는 기본값이 없는가? (또는 최소한인가?)
- [ ] 민감정보(비밀번호, API 키)는 `terraform.tfvars`에 넣지 않았는가?
- [ ] `.gitignore`에 `terraform.tfvars`를 추가했는가?

---

## 🔗 관련 파일
- [modules/network/variables.tf](../../../modules/network/variables.tf) - 네트워크 모듈의 입력값
- [modules/loadbalancer/variables.tf](../../../modules/loadbalancer/variables.tf) - 로드밸런서 모듈의 입력값
- [environments/dev/main.tf](../../../environments/dev/main.tf) - 모듈 호출 방식 학습
