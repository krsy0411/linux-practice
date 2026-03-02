# ============================================================================
# NSG Module Variables
# ============================================================================

variable "resource_group_name" {
  description = "리소스 그룹 이름"
  type        = string
}

variable "location" {
  description = "Azure 리전"
  type        = string
}

variable "appgw_subnet_id" {
  description = "Application Gateway Subnet ID"
  type        = string
}

variable "appgw_subnet_cidr" {
  description = "Application Gateway Subnet CIDR (보안 규칙에서 사용)"
  type        = string
}

variable "app_subnet_id" {
  description = "App Subnet ID"
  type        = string
}

variable "app_subnet_cidr" {
  description = "App Subnet CIDR (보안 규칙에서 사용)"
  type        = string
}

variable "db_subnet_id" {
  description = "DB Subnet ID"
  type        = string
}

variable "db_subnet_cidr" {
  description = "DB Subnet CIDR (보안 규칙에서 사용)"
  type        = string
}

variable "tags" {
  description = "리소스에 적용할 태그"
  type        = map(string)
  default     = {}
}
