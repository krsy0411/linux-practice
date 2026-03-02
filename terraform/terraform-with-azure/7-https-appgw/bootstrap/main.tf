# ============================================================================
# Terraform Bootstrap: 원격 상태 파일 저장소 초기화
# ============================================================================
# 목적: Terraform 상태 파일을 Azure Storage에 저장하기 위한 초기 설정
#
# 실행 순서:
# 1. 이 bootstrap을 먼저 apply
# 2. 출력된 Storage Account 정보를 environments/dev/backend.tf에 입력
# 3. 이후 environments/dev에서 terraform init을 실행
# ============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}

provider "azurerm" {
  features {}
}

# ============================================================================
# Resource Group: 상태 파일 저장을 위한 리소스 그룹
# ============================================================================
resource "azurerm_resource_group" "tfstate" {
  name     = var.tfstate_resource_group_name
  location = var.location

  tags = {
    Environment = "shared"           # 모든 환경(dev, staging, prod)에서 공유
    Purpose     = "terraform-state"  # Terraform 상태 파일 저장 전용
    ManagedBy   = "terraform"
    Project     = "7-https-appgw"
  }
}

# ============================================================================
# Storage Account: Terraform 상태 파일 저장소
# ============================================================================
# 주의사항:
# - Storage Account 이름은 Azure 전체에서 고유해야 함 (글로벌 유니크)
# - 소문자와 숫자만 사용 가능 (특수문자 불가)
# - 3~24자 제한
# - account_tier: "Standard"는 범용 스토리지 (상태 파일에 충분)
# - account_replication_type: "LRS"는 로컬 중복 (비용 효율적)
# ============================================================================
resource "azurerm_storage_account" "tfstate" {
  name                     = var.tfstate_storage_account_name
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"           # Standard vs Premium
  account_replication_type = "LRS"                # LRS(로컬 중복) vs GRS(지역 중복)

  # 보안 설정
  min_tls_version                 = "TLS1_2"      # 최소 TLS 버전 강제
  allow_nested_items_to_be_public = false         # 공개 액세스 차단

  tags = {
    Environment = "shared"
    Purpose     = "terraform-state"
    ManagedBy   = "terraform"
    Project     = "7-https-appgw"
  }
}

# ============================================================================
# Storage Container: 상태 파일을 저장할 컨테이너
# ============================================================================
# - Container는 Storage Account 내의 논리적 폴더
# - 여러 환경(dev, staging, prod)별로 다른 컨테이너를 만들 수도 있음
# - container_access_type = "private": 인증 없이는 접근 불가
# ============================================================================
resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}
