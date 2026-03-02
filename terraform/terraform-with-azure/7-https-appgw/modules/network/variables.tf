# ============================================================================
# Network Module Variables
# ============================================================================

variable "resource_group_name" {
  description = "리소스 그룹 이름"
  type        = string

  validation {
    condition     = length(var.resource_group_name) > 0
    error_message = "리소스 그룹 이름은 비어있을 수 없습니다."
  }
}

variable "location" {
  description = "Azure 리전"
  type        = string

  validation {
    condition     = contains(["Korea Central", "Korea South"], var.location)
    error_message = "한국 리전(Korea Central 또는 Korea South)을 선택해주세요."
  }
}

variable "vnet_name" {
  description = "Virtual Network 이름"
  type        = string

  validation {
    condition     = length(var.vnet_name) > 0
    error_message = "VNet 이름은 비어있을 수 없습니다."
  }
}

variable "vnet_cidr" {
  description = <<-EOT
    VNet CIDR 블록 (예: 10.10.0.0/16)
    - /16: 65,536개 IP 주소 (권장)
    - /20: 4,096개 IP 주소
  EOT
  type        = string

  validation {
    condition     = can(cidrhost(var.vnet_cidr, 0))
    error_message = "올바른 CIDR 형식이어야 합니다 (예: 10.10.0.0/16)."
  }
}

variable "appgw_subnet_cidr" {
  description = <<-EOT
    Application Gateway 전용 서브넷 CIDR (Tier 1)
    - Application Gateway만 배치 가능
    - 최소 /27 (32개 IP) 권장
    - 예: 10.10.0.0/27
  EOT
  type        = string

  validation {
    condition     = can(cidrhost(var.appgw_subnet_cidr, 0))
    error_message = "올바른 CIDR 형식이어야 합니다."
  }

  validation {
    condition     = tonumber(split("/", var.appgw_subnet_cidr)[1]) <= 27
    error_message = "Application Gateway 서브넷은 최소 /27 이상이어야 합니다."
  }
}

variable "app_subnet_cidr" {
  description = <<-EOT
    App Subnet CIDR (Tier 2 - VMSS용)
    - VMSS VM들이 이 서브넷에 배치됨
    - Private IP만 사용
    - 예: 10.10.1.0/24 (256개 IP)
  EOT
  type        = string

  validation {
    condition     = can(cidrhost(var.app_subnet_cidr, 0))
    error_message = "올바른 CIDR 형식이어야 합니다."
  }
}

variable "db_subnet_cidr" {
  description = <<-EOT
    DB Subnet CIDR (Tier 3 - 데이터베이스용)
    - Azure Database for MySQL/PostgreSQL 배치
    - 완전한 Private 서브넷
    - 예: 10.10.2.0/24 (256개 IP)
  EOT
  type        = string

  validation {
    condition     = can(cidrhost(var.db_subnet_cidr, 0))
    error_message = "올바른 CIDR 형식이어야 합니다."
  }
}

variable "tags" {
  description = "리소스에 적용할 태그"
  type        = map(string)
  default     = {}
}
