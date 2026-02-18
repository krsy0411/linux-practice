# Terraform 기초 학습

> **학습 목표**: Terraform의 철학, 핵심 개념, 그리고 실무 워크플로우를 이해합니다.

---

## 1. Terraform은 왜 등장했을까? 🤔

### 전통적인 인프라 관리의 문제점

과거에는 인프라를 이렇게 관리했습니다:

1. **수동 작업** (Manual Process)
   - 웹 콘솔에 로그인해서 클릭클릭...
   - 설정을 하나씩 입력하고 버튼 누르기
   - 반복 작업에 시간 소모, 실수 가능성 높음

2. **문서화의 어려움**
   - "누가 언제 무엇을 만들었지?"
   - 인프라가 어떻게 구성되어 있는지 파악 불가
   - 담당자가 바뀌면 인수인계 어려움

3. **재현 불가능**
   - 개발/테스트/운영 환경을 똑같이 만들기 어려움
   - "내 로컬에서는 되는데요?" 문제 발생

4. **협업의 어려움**
   - 여러 사람이 동시에 작업하면 충돌
   - 누가 무엇을 변경했는지 추적 불가

### Terraform의 철학: Infrastructure as Code (IaC)

Terraform은 이런 철학으로 탄생했습니다:

#### 📝 **코드로 인프라를 정의한다**
```hcl
resource "azurerm_resource_group" "rg" {
  name     = "rg-terraform-study"
  location = "Korea Central"
}
```
인프라를 코드로 작성하면:
- **버전 관리** 가능 (Git 사용)
- **리뷰** 가능 (Pull Request)
- **재사용** 가능 (복사해서 사용)

#### 🔄 **선언형 (Declarative) 방식**
"어떻게 만들지"가 아니라 **"무엇을 원하는지"** 선언합니다.

```hcl
# "리소스 그룹이 있어야 한다"고 선언
resource "azurerm_resource_group" "rg" {
  name     = "rg-terraform-study"
  location = "Korea Central"
}
```

Terraform이 알아서:
- 없으면 → 생성
- 있는데 설정이 다르면 → 수정
- 코드에서 삭제되면 → 제거

#### 🎯 **멱등성 (Idempotency)**
같은 코드를 여러 번 실행해도 결과는 동일합니다.
- 이미 존재하면 다시 만들지 않음
- 안전하게 여러 번 실행 가능

#### 🌍 **Multi-Cloud 지원**
하나의 도구로 여러 클라우드를 관리:
- Azure, AWS, GCP
- Kubernetes, Docker
- GitHub, Datadog 등

### Terraform의 핵심 가치

| 가치 | 의미 | 실무 예시 |
|------|------|----------|
| **자동화** | 수동 작업 제거 | 클릭 100번 → 코드 10줄 |
| **일관성** | 항상 같은 결과 | Dev/Stage/Prod 환경 동일하게 구성 |
| **가시성** | 무엇이 있는지 명확 | 코드만 보면 인프라 구조 파악 |
| **협업** | 팀 단위 작업 | Git으로 코드 리뷰 및 변경 이력 관리 |
| **안전성** | 실행 전 검증 | `plan`으로 미리 확인 후 `apply` |

---

## 2. Terraform 핵심 개념 및 문법 🎓

### 2.1 핵심 구성 요소

#### 🏗️ **Provider** (프로바이더)
클라우드/서비스와 통신하는 플러그인입니다.

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"  # 어디서 가져올지
      version = "~> 3.0"              # 어떤 버전을 쓸지
    }
  }
}

provider "azurerm" {
  features {}  # Azure 프로바이더 설정
}
```

**역할**:
- Azure API와 통신
- 인증 처리
- 리소스 생성/수정/삭제 수행

#### 📦 **Resource** (리소스)
실제로 만들 인프라 구성 요소입니다.

```hcl
resource "azurerm_resource_group" "rg" {
  name     = "rg-terraform-study"
  location = "Korea Central"
}
```

**구조 분석**:
```hcl
resource "리소스_타입" "로컬_이름" {
  속성 = "값"
}
```

- **리소스 타입**: `azurerm_resource_group` (Azure 리소스 그룹)
- **로컬 이름**: `rg` (Terraform 코드 내에서 참조할 이름)
- **속성**: `name`, `location` 등

#### 🔗 **리소스 참조**
다른 리소스의 정보를 사용할 수 있습니다:

```hcl
# 리소스 그룹 생성
resource "azurerm_resource_group" "rg" {
  name     = "rg-terraform-study"
  location = "Korea Central"
}

# 리소스 그룹을 참조하는 가상 네트워크
resource "azurerm_virtual_network" "vnet" {
  name                = "my-vnet"
  resource_group_name = azurerm_resource_group.rg.name      # 참조!
  location            = azurerm_resource_group.rg.location  # 참조!
  address_space       = ["10.0.0.0/16"]
}
```

**참조 문법**: `리소스타입.로컬이름.속성`

#### 💾 **State** (상태 파일)
`terraform.tfstate` 파일은 현재 인프라의 "실제 상태"를 기록합니다.

```json
{
  "resources": [
    {
      "type": "azurerm_resource_group",
      "name": "rg",
      "instances": [
        {
          "attributes": {
            "id": "/subscriptions/.../rg-terraform-study",
            "name": "rg-terraform-study",
            "location": "koreacentral"
          }
        }
      ]
    }
  ]
}
```

**역할**:
- 코드와 실제 인프라를 매핑
- 무엇이 변경되었는지 감지
- 팀원 간 상태 공유 (원격 백엔드 사용 시)

**⚠️ 주의**: 수동으로 편집하면 안 됩니다!

### 2.2 HCL 문법 기초

#### 📝 주석
```hcl
# 한 줄 주석

// 이것도 한 줄 주석

/*
  여러 줄
  주석
*/
```

#### 🔤 데이터 타입
```hcl
# 문자열
name = "my-resource"

# 숫자
count = 3

# 불린
enabled = true

# 리스트
zones = ["zone-a", "zone-b", "zone-c"]

# 맵 (객체)
tags = {
  Environment = "Production"
  Team        = "DevOps"
}
```

#### 🔗 표현식
```hcl
# 문자열 보간
name = "rg-${var.environment}-${var.project}"

# 참조
resource_group_name = azurerm_resource_group.rg.name

# 함수 사용
location = lower("KOREA CENTRAL")  # "korea central"
```

### 2.3 파일 구조

```
프로젝트/
├── provider.tf         # 프로바이더 설정
├── main.tf             # 주요 리소스 정의
├── variables.tf        # 변수 선언 (선택)
├── outputs.tf          # 출력 정의 (선택)
├── terraform.tfstate   # 상태 파일 (자동 생성)
└── .terraform/         # 플러그인 (자동 생성)
```

**파일 이름은 자유**지만, 관례를 따르면 협업이 쉬워집니다.

---

## 3. Terraform 워크플로우 🔄

### 3.1 기본 워크플로우

Terraform은 **Write → Plan → Apply** 사이클로 동작합니다:

```
┌─────────────┐
│  1. Write   │  코드 작성
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  2. Init    │  초기화
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  3. Plan    │  실행 계획 확인
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  4. Apply   │  실제 적용
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 인프라 생성  │
└─────────────┘
```

### 3.2 명령어 상세 설명

#### 1️⃣ **코드 작성**
```hcl
# main.tf
resource "azurerm_resource_group" "rg" {
  name     = "rg-terraform-study"
  location = "Korea Central"
}
```

#### 2️⃣ **terraform init** - 초기화
```bash
terraform init
```

**수행 작업**:
- 프로바이더 플러그인 다운로드 (`.terraform/` 디렉터리)
- 백엔드 초기화
- 모듈 다운로드 (사용 시)

**언제 실행?**
- 처음 프로젝트 시작할 때
- 새로운 프로바이더 추가했을 때
- 다른 사람의 코드를 클론했을 때

**출력 예시**:
```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/azurerm versions matching "~> 3.0"...
- Installing hashicorp/azurerm v3.117.1...

Terraform has been successfully initialized!
```

#### 3️⃣ **terraform plan** - 실행 계획
```bash
terraform plan
```

**수행 작업**:
- 현재 상태와 코드를 비교
- 어떤 변경이 일어날지 미리 보여줌
- **실제 리소스는 변경하지 않음** (안전)

**출력 기호**:
- `+` : 새로 생성될 리소스
- `-` : 삭제될 리소스
- `~` : 수정될 리소스
- `-/+` : 삭제 후 재생성

**출력 예시**:
```
Terraform will perform the following actions:

  # azurerm_resource_group.rg will be created
  + resource "azurerm_resource_group" "rg" {
      + id       = (known after apply)
      + location = "koreacentral"
      + name     = "rg-terraform-study"
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

#### 4️⃣ **terraform apply** - 적용
```bash
terraform apply
```

**수행 작업**:
- `plan` 결과를 다시 보여줌
- 확인을 요청 (`yes` 입력 필요)
- 실제로 인프라를 생성/수정/삭제
- 상태 파일 업데이트

**팁**: `-auto-approve` 플래그로 확인 생략 가능
```bash
terraform apply -auto-approve
```

**출력 예시**:
```
azurerm_resource_group.rg: Creating...
azurerm_resource_group.rg: Creation complete after 2s

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

#### 5️⃣ **terraform destroy** - 삭제
```bash
terraform destroy
```

**수행 작업**:
- 관리 중인 모든 리소스를 삭제
- 확인 요청 (`yes` 입력)

**⚠️ 주의**: 프로덕션에서는 신중하게 사용!

### 3.3 보조 명령어

```bash
# 코드 포맷 정리
terraform fmt

# 문법 검증
terraform validate

# 현재 상태 보기
terraform show

# 상태 파일의 리소스 목록
terraform state list
```

### 3.4 실무 워크플로우 예시

#### 🎯 **시나리오**: 새 리소스 추가하기

```bash
# 1. 코드 작성 (main.tf 수정)

# 2. 포맷 정리
terraform fmt

# 3. 문법 검증
terraform validate

# 4. 계획 확인 (실제로 무엇이 바뀔지 확인)
terraform plan

# 5. 출력 확인 후 적용
terraform apply

# 6. 생성 확인
terraform show
```

#### 🎯 **시나리오**: 기존 리소스 수정하기

```bash
# 1. 코드 수정 (예: location 변경)

# 2. 계획 확인 - "재생성"이 필요한지 체크!
terraform plan
# 출력: ~ modify 또는 -/+ replace

# 3. 안전하다면 적용
terraform apply
```

#### 🎯 **시나리오**: 협업 (팀 작업)

```bash
# 1. Git에서 최신 코드 받기
git pull

# 2. Terraform 초기화 (프로바이더 업데이트)
terraform init

# 3. 현재 상태와 비교
terraform plan

# 4. 적용
terraform apply

# 5. 코드 수정 및 커밋
git add .
git commit -m "Add new resources"
git push
```

### 3.5 워크플로우 베스트 프랙티스

#### ✅ **항상 Plan 먼저**
```bash
terraform plan  # 먼저 확인
terraform apply # 그 다음 적용
```

#### ✅ **작은 단위로 자주 Apply**
```hcl
# 한 번에 100개 리소스 ❌
# 10개씩 나눠서 적용 ✅
```

#### ✅ **State 파일 안전하게 관리**
- 로컬 작업: 실수로 삭제하지 않기
- 팀 작업: 원격 백엔드 사용 (Azure Storage, S3 등)

#### ✅ **Version Control**
```bash
git add provider.tf main.tf
git commit -m "Add resource group"
git push
```

---

## 📚 학습 체크리스트

### ✅ Terraform 철학
- [ ] Infrastructure as Code(IaC)의 의미 이해
- [ ] 선언형(Declarative) 방식 이해
- [ ] Terraform의 핵심 가치 이해

### ✅ 핵심 개념
- [ ] Provider의 역할
- [ ] Resource 정의 방법
- [ ] 리소스 참조 문법
- [ ] State 파일의 역할과 중요성
- [ ] HCL 기본 문법

### ✅ 워크플로우
- [ ] Write → Init → Plan → Apply 사이클 이해
- [ ] 각 명령어의 역할과 사용 시점
- [ ] 실무 워크플로우 적용 방법

---

## 4. Terraform 고급 개념 미리보기 🔮

> 다음 폴더들에서 상세히 다루겠지만, 미리 개념을 이해하고 가면 학습이 훨씬 수월합니다.

### 4.1 Variables (변수) - 유연성 확보

#### 🤔 왜 변수가 필요할까?

**하드코딩 방식의 문제점**:
```hcl
resource "azurerm_resource_group" "rg" {
  name     = "rg-terraform-study"      # 고정된 값
  location = "Korea Central"           # 고정된 값
}
```

**문제**:
- 환경마다 다른 값을 쓰고 싶을 때? (Dev, Stage, Prod)
- 여러 곳에서 같은 값을 쓴다면? (변경 시 모두 수정)
- 민감한 정보(비밀번호 등)를 코드에 직접 쓰면? (보안 위험)

#### 📝 변수 사용 방식

**1단계: 변수 선언** (`variables.tf`)
```hcl
variable "resource_group_name" {
  description = "리소스 그룹 이름"
  type        = string
  default     = "rg-terraform-study"
}

variable "location" {
  description = "Azure 리전"
  type        = string
  default     = "Korea Central"
}

variable "environment" {
  description = "환경 (dev, stage, prod)"
  type        = string
}
```

**2단계: 변수 사용** (`main.tf`)
```hcl
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name      # 변수 참조
  location = var.location                 # 변수 참조
  
  tags = {
    Environment = var.environment
  }
}
```

**3단계: 값 전달 방법**

방법 1: **명령줄에서 전달**
```bash
terraform apply -var="environment=dev"
```

방법 2: **파일로 전달** (`terraform.tfvars`)
```hcl
resource_group_name = "rg-myproject-dev"
location           = "Korea Central"
environment        = "dev"
```

방법 3: **환경 변수**
```bash
export TF_VAR_environment="dev"
terraform apply
```

#### 🎯 변수의 장점

| 장점 | 설명 |
|------|------|
| **재사용성** | 같은 코드로 여러 환경 배포 |
| **유지보수성** | 한 곳만 수정하면 됨 |
| **보안** | 민감 정보를 파일에서 분리 |
| **문서화** | description으로 의도 명확화 |

#### 💡 변수 타입

```hcl
# 문자열
variable "name" {
  type = string
}

# 숫자
variable "instance_count" {
  type = number
}

# 불린
variable "enable_backup" {
  type = bool
}

# 리스트
variable "availability_zones" {
  type = list(string)
  default = ["1", "2", "3"]
}

# 맵
variable "tags" {
  type = map(string)
  default = {
    Environment = "Dev"
    Team        = "Platform"
  }
}

# 객체 (복잡한 구조)
variable "network_config" {
  type = object({
    vnet_name    = string
    address_space = list(string)
    subnets = list(object({
      name   = string
      prefix = string
    }))
  })
}
```

#### 🔒 민감한 변수 처리

```hcl
variable "admin_password" {
  description = "관리자 비밀번호"
  type        = string
  sensitive   = true  # Plan/Apply 출력에서 숨김
}
```

**Best Practice**:
- 비밀번호, API 키 등은 `sensitive = true` 설정
- Git에 커밋하지 않기 (`.gitignore`에 `*.tfvars` 추가)
- Azure Key Vault 같은 비밀 관리 서비스 사용

---

### 4.2 Outputs (출력) - 정보 추출

#### 🤔 왜 출력이 필요할까?

리소스를 생성한 후:
- 생성된 리소스의 ID를 알고 싶다
- 다른 팀원에게 정보를 공유하고 싶다
- 다른 Terraform 프로젝트에서 이 값을 사용하고 싶다

#### 📤 출력 정의하기 (`outputs.tf`)

```hcl
output "resource_group_id" {
  description = "리소스 그룹의 Azure ID"
  value       = azurerm_resource_group.rg.id
}

output "resource_group_name" {
  description = "리소스 그룹 이름"
  value       = azurerm_resource_group.rg.name
}

output "location" {
  description = "배포된 지역"
  value       = azurerm_resource_group.rg.location
}
```

#### 💻 출력 확인 방법

**Apply 후 자동 출력**:
```bash
$ terraform apply

...

Outputs:

resource_group_id   = "/subscriptions/xxx/resourceGroups/rg-terraform-study"
resource_group_name = "rg-terraform-study"
location           = "koreacentral"
```

**명시적 출력 확인**:
```bash
$ terraform output

resource_group_id   = "/subscriptions/xxx/resourceGroups/rg-terraform-study"
resource_group_name = "rg-terraform-study"
location           = "koreacentral"
```

**특정 출력만 보기**:
```bash
$ terraform output resource_group_name
"rg-terraform-study"
```

**JSON 형식으로 출력**:
```bash
$ terraform output -json
{
  "resource_group_id": {
    "value": "/subscriptions/xxx/...",
    "type": "string"
  }
}
```

#### 🔗 출력의 활용

**1. 다른 Terraform 프로젝트에서 사용** (Data Source)
```hcl
# 프로젝트 A에서 출력
output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

# 프로젝트 B에서 가져오기
data "terraform_remote_state" "network" {
  backend = "azurerm"
  config = {
    # ...
  }
}

resource "azurerm_subnet" "app" {
  virtual_network_name = data.terraform_remote_state.network.outputs.vnet_id
}
```

**2. CI/CD 파이프라인에서 사용**
```bash
# GitHub Actions 예시
- name: Get RG Name
  id: tf_output
  run: echo "rg_name=$(terraform output -raw resource_group_name)" >> $GITHUB_OUTPUT
```

**3. 문서화 목적**
```hcl
output "connection_info" {
  description = "접속 정보 요약"
  value = {
    resource_group = azurerm_resource_group.rg.name
    location       = azurerm_resource_group.rg.location
    vnet_name      = azurerm_virtual_network.vnet.name
  }
}
```

---

### 4.3 Modules (모듈) - 코드 재사용

#### 🤔 왜 모듈이 필요할까?

**문제 상황**:
- 동일한 네트워크 구조를 여러 환경에 배포
- Dev, Stage, Prod에서 같은 패턴 반복
- 코드 복사-붙여넣기 → 유지보수 지옥

**해결책**: 모듈로 패키지화!

#### 📦 모듈이란?

모듈은 **재사용 가능한 Terraform 코드의 묶음**입니다.

```
프로젝트/
├── main.tf
├── modules/
│   └── network/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
```

#### 🏗️ 모듈 만들기

**모듈 정의** (`modules/network/main.tf`):
```hcl
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = var.address_space
}

resource "azurerm_subnet" "subnets" {
  for_each = var.subnets
  
  name                 = each.value.name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [each.value.address_prefix]
}
```

**모듈 변수** (`modules/network/variables.tf`):
```hcl
variable "resource_group_name" {
  description = "리소스 그룹 이름"
  type        = string
}

variable "location" {
  description = "Azure 리전"
  type        = string
}

variable "vnet_name" {
  description = "VNet 이름"
  type        = string
}

variable "address_space" {
  description = "VNet 주소 공간"
  type        = list(string)
}

variable "subnets" {
  description = "서브넷 목록"
  type = map(object({
    name           = string
    address_prefix = string
  }))
}
```

**모듈 출력** (`modules/network/outputs.tf`):
```hcl
output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "subnet_ids" {
  value = {
    for k, subnet in azurerm_subnet.subnets : k => subnet.id
  }
}
```

#### 🔧 모듈 사용하기

**루트 모듈에서 호출** (`main.tf`):
```hcl
module "dev_network" {
  source = "./modules/network"
  
  resource_group_name = "rg-myapp-dev"
  location           = "Korea Central"
  vnet_name          = "vnet-dev"
  address_space      = ["10.0.0.0/16"]
  
  subnets = {
    web = {
      name           = "subnet-web"
      address_prefix = "10.0.1.0/24"
    }
    app = {
      name           = "subnet-app"
      address_prefix = "10.0.2.0/24"
    }
  }
}

module "prod_network" {
  source = "./modules/network"
  
  resource_group_name = "rg-myapp-prod"
  location           = "Korea Central"
  vnet_name          = "vnet-prod"
  address_space      = ["10.1.0.0/16"]
  
  subnets = {
    web = {
      name           = "subnet-web"
      address_prefix = "10.1.1.0/24"
    }
    app = {
      name           = "subnet-app"
      address_prefix = "10.1.2.0/24"
    }
  }
}
```

**모듈 출력 참조**:
```hcl
output "dev_vnet_id" {
  value = module.dev_network.vnet_id
}
```

#### 🌍 공개 모듈 레지스트리

**Terraform Registry**에서 검증된 모듈 가져오기:
```hcl
module "network" {
  source  = "Azure/network/azurerm"
  version = "3.5.0"
  
  resource_group_name = "rg-myapp"
  # ...
}
```

- 공식 Azure 모듈: [registry.terraform.io/namespaces/Azure](https://registry.terraform.io/namespaces/Azure)
- 커뮤니티 검증 완료
- 베스트 프랙티스 적용됨

#### 💡 모듈 사용 시 장점

| 장점 | 설명 |
|------|------|
| **재사용성** | 한 번 작성, 여러 곳에서 사용 |
| **유지보수** | 모듈 수정 → 모든 사용처에 적용 |
| **추상화** | 복잡한 내부 구현 숨김 |
| **일관성** | 표준화된 인프라 패턴 |
| **테스트** | 모듈 단위로 테스트 가능 |

#### ⚠️ 모듈 사용 시 주의사항

```bash
# 모듈을 추가/수정했을 때 반드시 실행
terraform init

# 모듈 업데이트
terraform init -upgrade
```

---

### 4.4 Remote State (원격 상태 관리) - 팀 협업

#### 🤔 왜 원격 상태가 필요할까?

**로컬 상태 파일의 문제점**:

1. **협업 불가**
   - 각자의 로컬에 상태 파일이 따로 존재
   - 동시 작업 시 충돌 발생

2. **백업 부족**
   - 로컬 파일 손실 시 복구 불가
   - 중요한 인프라 정보 분실

3. **보안 위험**
   - 상태 파일에 민감 정보 포함 가능
   - Git에 잘못 커밋하면 노출

4. **일관성 문제**
   - "너 최신 상태 파일 가지고 있어?"
   - 버전 불일치로 인한 오류

#### ☁️ 원격 백엔드 (Remote Backend)

**Azure Storage를 백엔드로 사용**:

**0단계: Storage Account 생성** (Azure Portal 또는 CLI)
```bash
# 리소스 그룹 생성
az group create --name rg-terraform-state --location koreacentral

# Storage Account 생성
az storage account create \
  --name tfstatestorage123 \
  --resource-group rg-terraform-state \
  --location koreacentral \
  --sku Standard_LRS

# 컨테이너 생성
az storage container create \
  --name tfstate \
  --account-name tfstatestorage123
```

**1단계: Backend 설정** (`provider.tf`):
```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  
  # 원격 백엔드 설정
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstatestorage123"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"  # 상태 파일 이름
  }
}

provider "azurerm" {
  features {}
}
```

**2단계: 초기화**
```bash
terraform init
```

**출력**:
```
Initializing the backend...

Successfully configured the backend "azurerm"!
```

#### 🔒 State Locking (상태 잠금)

**문제**: 두 명이 동시에 `terraform apply`를 실행하면?

**해결**: State Locking
- Azure Storage는 자동으로 Blob Lease를 사용한 잠금 지원
- 한 명이 작업 중이면 다른 사람은 대기

```bash
# A 사용자가 apply 중...
$ terraform apply
Acquiring state lock. This may take a few moments...

# B 사용자가 동시에 apply 시도
$ terraform apply
Error: Error acquiring the state lock

Lock Info:
  ID:        abc123...
  Operation: OperationTypeApply
  Who:       user-a@company.com
  Created:   2026-02-18 10:30:00 UTC
```

**강제 잠금 해제** (신중하게!):
```bash
terraform force-unlock <lock-id>
```

#### 🌐 Backend 유형 비교

| Backend | 장점 | 단점 | 추천 |
|---------|------|------|------|
| **Local** | 간단, 빠름 | 협업 불가, 백업 없음 | 개인 학습용 |
| **Azure Storage** | 무료 tier, 잠금 지원, 보안 | Azure 의존적 | Azure 사용 시 ✅ |
| **AWS S3** | 안정적, DynamoDB 잠금 | AWS 계정 필요 | AWS 사용 시 |
| **Terraform Cloud** | 무료 tier, UI, 협업 기능 | 외부 의존 | 소규모 팀 |

#### 📊 원격 상태 마이그레이션

**로컬 → 원격으로 전환**:

```bash
# 1. provider.tf에 backend 설정 추가

# 2. 초기화 (기존 상태 복사 여부 물어봄)
$ terraform init

Terraform detected that the configuration specified a backend
that already exists. Would you like to copy existing state to
the new backend?

  Enter a value: yes

Successfully configured the backend "azurerm"!
```

**원격 → 로컬로 전환** (필요 시):
```bash
# 1. provider.tf에서 backend 블록 제거

# 2. 초기화
$ terraform init -migrate-state
```

#### 🔐 보안 베스트 프랙티스

**1. Storage Account 접근 제한**:
```bash
az storage account update \
  --name tfstatestorage123 \
  --resource-group rg-terraform-state \
  --default-action Deny

az storage account network-rule add \
  --account-name tfstatestorage123 \
  --resource-group rg-terraform-state \
  --ip-address <your-ip>
```

**2. 암호화 활성화**:
```hcl
backend "azurerm" {
  # ...
  use_azuread_auth = true  # Azure AD 인증 사용
}
```

**3. RBAC 권한 설정**:
- 개발자: Storage Blob Data Contributor
- CI/CD: Storage Blob Data Contributor
- 읽기 전용: Storage Blob Data Reader

#### 💡 워크플로우 예시

**팀 협업 시나리오**:

```bash
# 개발자 A
$ git pull                    # 최신 코드 가져오기
$ terraform init              # 백엔드 설정 동기화
$ terraform plan              # 계획 확인
$ terraform apply             # 적용 (상태 파일 자동 업로드)
$ git add .
$ git commit -m "Add new resources"
$ git push

# 개발자 B
$ git pull                    # A의 코드 변경 가져오기
$ terraform init              # 필요 시
$ terraform plan              # 최신 상태 파일로 계획 확인
```

---

## 🎓 선생님의 마무리 조언

### 이번 폴더에서 배운 것
이 `1-basic-resource-creation-test` 폴더는 Terraform의 가장 기본적인 골격입니다:
- Provider 설정하기
- Resource 하나 만들기
- 워크플로우 익히기

그리고 앞으로 배울 고급 개념들을 미리 살펴봤습니다:
- **Variables**: 코드의 유연성
- **Outputs**: 정보 추출 및 공유
- **Modules**: 코드 재사용
- **Remote State**: 팀 협업

### 학습 로드맵

```
✅ 1. 기초
   ├── Terraform 철학 이해
   ├── 기본 문법 (Provider, Resource)
   └── 워크플로우 (Init, Plan, Apply)

→ 2. 네트워크 구성 (다음 폴더)
   ├── VNet & Subnet
   ├── 리소스 참조
   └── 의존성 관리

→ 3. 보안 설정
   ├── NSG (Network Security Group)
   └── 보안 규칙

→ 4. 실전 아키텍처
   ├── 3-Tier 구조
   ├── Variables 활용
   └── Modules 구성

→ 5. 프로덕션 준비
   ├── Remote State 설정
   ├── CI/CD 통합
   └── 모니터링
```

### 핵심 원칙 (반복!)

1. **항상 Plan 먼저, Apply는 나중에**
   ```bash
   terraform plan   # 확인
   terraform apply  # 실행
   ```

2. **State 파일은 손대지 않기**
   - 자동 생성되는 파일
   - Git에 커밋하지 않기
   - 원격 백엔드 사용 (팀 작업 시)

3. **코드는 Git으로 관리하기**
   ```bash
   git add provider.tf main.tf variables.tf
   git commit -m "Initial terraform setup"
   ```

4. **문서화하기**
   - 변수에 description 추가
   - 주석으로 의도 설명
   - README.md 작성

### 실무 팁

**🎯 변수 파일 구조**:
```
프로젝트/
├── provider.tf           # 프로바이더 & 백엔드
├── main.tf               # 주요 리소스
├── variables.tf          # 변수 선언
├── outputs.tf            # 출력 정의
├── terraform.tfvars      # 기본값 (Git 제외)
├── dev.tfvars           # 개발 환경
├── prod.tfvars          # 프로덕션 환경
└── .gitignore           # *.tfvars, *.tfstate
```

**🎯 명명 규칙**:
```hcl
# 리소스 이름 (Azure에 생성되는 실제 이름)
name = "rg-${var.project}-${var.environment}"
# 결과: rg-myapp-dev

# 로컬 이름 (Terraform 코드 내)
resource "azurerm_resource_group" "main" {  # 짧고 명확하게
  # ...
}
```

**🎯 태그 활용**:
```hcl
variable "common_tags" {
  type = map(string)
  default = {
    ManagedBy   = "Terraform"
    Environment = "Production"
    CostCenter  = "Engineering"
    Owner       = "platform-team@company.com"
  }
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.common_tags
}
```

---

**준비되셨나요? 다음 폴더로 넘어가봅시다!** 🚀
