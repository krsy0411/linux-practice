# ============================================================================
# Backend Configuration: Terraform 상태 파일 저장소
# ============================================================================
# bootstrap 실행 후 생성된 Storage Account 정보로 수정
#
# 설정 방법:
# 1. bootstrap/ 폴더에서 terraform apply 실행
# 2. 출력된 값을 아래에 입력
# 3. 환경변수 설정: export ARM_ACCESS_KEY="<primary_access_key>"
# 4. terraform init 실행
# ============================================================================

terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"                  # bootstrap에서 생성한 Resource Group
    storage_account_name = "tfstate7httpsappgw"          # bootstrap에서 생성한 Storage Account
    container_name       = "tfstate"                     # bootstrap에서 생성한 Container
    key                  = "dev.terraform.tfstate"       # 환경별로 다른 키 사용
  }
}
