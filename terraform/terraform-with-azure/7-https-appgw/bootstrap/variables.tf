# ============================================================================
# Bootstrap Variables: 상태 파일 저장소 설정을 위한 변수
# ============================================================================

variable "tfstate_resource_group_name" {
  description = "Terraform 상태 파일을 저장할 Resource Group 이름"
  type        = string
  default     = "tfstate-rg"

  validation {
    condition     = length(var.tfstate_resource_group_name) > 0 && length(var.tfstate_resource_group_name) <= 90
    error_message = "Resource Group 이름은 1~90자 사이여야 합니다."
  }
}

variable "tfstate_storage_account_name" {
  description = <<-EOT
    Terraform 상태 파일을 저장할 Storage Account 이름
    - Azure 전체에서 글로벌하게 고유해야 함
    - 소문자와 숫자만 허용
    - 3~24자 제한
  EOT
  type        = string
  default     = "tfstate7httpsappgw"

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.tfstate_storage_account_name))
    error_message = "Storage Account 이름은 소문자와 숫자만 사용하며 3~24자여야 합니다."
  }
}

variable "location" {
  description = "Azure 리전 위치"
  type        = string
  default     = "Korea Central"

  validation {
    condition     = contains(["Korea Central", "Korea South", "East Asia", "Southeast Asia", "Japan East", "Japan West"], var.location)
    error_message = "지원되는 아시아 리전을 선택해주세요."
  }
}
