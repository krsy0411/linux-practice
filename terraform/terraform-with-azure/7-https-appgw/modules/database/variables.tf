# ============================================================================
# Database Module Variables
# ============================================================================

variable "resource_group_name" {
  description = "리소스 그룹 이름"
  type        = string
}

variable "location" {
  description = "Azure 리전"
  type        = string
}

variable "mysql_server_name" {
  description = "MySQL 서버 이름 (Azure 전체에서 고유해야 함)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{3,63}$", var.mysql_server_name))
    error_message = "MySQL 서버 이름은 소문자, 숫자, 하이픈만 사용하며 3~63자여야 합니다."
  }
}

variable "admin_username" {
  description = "MySQL 관리자 사용자 이름"
  type        = string
  default     = "mysqladmin"

  validation {
    condition     = !contains(["admin", "administrator", "root", "guest"], var.admin_username)
    error_message = "예약된 사용자 이름은 사용할 수 없습니다."
  }
}

variable "admin_password" {
  description = <<-EOT
    MySQL 관리자 비밀번호
    - 최소 8자, 최대 128자
    - 대문자, 소문자, 숫자, 특수문자 포함
  EOT
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.admin_password) >= 8 && length(var.admin_password) <= 128
    error_message = "비밀번호는 8~128자여야 합니다."
  }
}

variable "database_name" {
  description = "생성할 데이터베이스 이름"
  type        = string
  default     = "appdb"
}

variable "sku_name" {
  description = <<-EOT
    MySQL 서버 SKU
    - B_Standard_B1ms: 1 vCore, 2GB RAM (개발/테스트)
    - GP_Standard_D2ds_v4: 2 vCore, 8GB RAM (프로덕션)
  EOT
  type        = string
  default     = "B_Standard_B1ms"
}

variable "storage_size_gb" {
  description = "스토리지 크기 (GB) - 최소 20GB"
  type        = number
  default     = 20

  validation {
    condition     = var.storage_size_gb >= 20 && var.storage_size_gb <= 16384
    error_message = "스토리지 크기는 20GB~16TB 사이여야 합니다."
  }
}

variable "backup_retention_days" {
  description = "백업 보관 일수 (1~35일)"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 35
    error_message = "백업 보관 일수는 1~35일 사이여야 합니다."
  }
}

variable "geo_redundant_backup_enabled" {
  description = "지역 중복 백업 활성화 여부 (비용 증가)"
  type        = bool
  default     = false
}

variable "enable_high_availability" {
  description = "고가용성 활성화 여부 (비용 2배 증가)"
  type        = bool
  default     = false
}

variable "vnet_id" {
  description = "VNet ID (Private DNS Zone 연결용)"
  type        = string
}

variable "db_subnet_id" {
  description = "MySQL 서버가 배치될 Subnet ID"
  type        = string
}

variable "tags" {
  description = "리소스에 적용할 태그"
  type        = map(string)
  default     = {}
}
