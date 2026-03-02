# ============================================================================
# Development Environment Variables
# ============================================================================
# 실제 값은 terraform.tfvars 파일에 정의
# ============================================================================

# ============================================================================
# 기본 설정
# ============================================================================
variable "resource_group_name" {
  description = "리소스 그룹 이름"
  type        = string
}

variable "location" {
  description = "Azure 리전"
  type        = string
  default     = "Korea Central"
}

# ============================================================================
# Network 설정
# ============================================================================
variable "vnet_name" {
  description = "Virtual Network 이름"
  type        = string
}

variable "vnet_cidr" {
  description = "VNet CIDR"
  type        = string
}

variable "appgw_subnet_cidr" {
  description = "Application Gateway Subnet CIDR"
  type        = string
}

variable "app_subnet_cidr" {
  description = "App Subnet CIDR"
  type        = string
}

variable "db_subnet_cidr" {
  description = "DB Subnet CIDR"
  type        = string
}

# ============================================================================
# Application Gateway 설정
# ============================================================================
variable "appgw_name" {
  description = "Application Gateway 이름"
  type        = string
}

variable "domain_name_label" {
  description = "Public IP DNS 레이블 (선택사항)"
  type        = string
  default     = null
}

variable "appgw_sku_name" {
  description = "Application Gateway SKU (Standard_v2 또는 WAF_v2)"
  type        = string
  default     = "Standard_v2"
}

variable "appgw_sku_tier" {
  description = "Application Gateway SKU Tier"
  type        = string
  default     = "Standard_v2"
}

variable "appgw_capacity" {
  description = "Application Gateway 인스턴스 수"
  type        = number
  default     = 2
}

variable "appgw_enable_autoscale" {
  description = "Application Gateway Auto Scaling 활성화"
  type        = bool
  default     = false
}

variable "appgw_autoscale_min_capacity" {
  description = "Application Gateway Auto Scaling 최소 인스턴스"
  type        = number
  default     = 2
}

variable "appgw_autoscale_max_capacity" {
  description = "Application Gateway Auto Scaling 최대 인스턴스"
  type        = number
  default     = 10
}

variable "ssl_certificate_data" {
  description = "SSL 인증서 데이터 (PFX, base64 인코딩)"
  type        = string
  sensitive   = true
}

variable "ssl_certificate_password" {
  description = "SSL 인증서 비밀번호"
  type        = string
  sensitive   = true
}

variable "ssl_policy_name" {
  description = "SSL Policy 이름"
  type        = string
  default     = "AppGwSslPolicy20220101"
}

variable "waf_mode" {
  description = "WAF 모드 (Detection 또는 Prevention)"
  type        = string
  default     = "Prevention"
}

# ============================================================================
# VMSS 설정
# ============================================================================
variable "vmss_name" {
  description = "VMSS 이름"
  type        = string
}

variable "vmss_vm_sku" {
  description = "VM SKU"
  type        = string
  default     = "Standard_B1s"
}

variable "vmss_admin_username" {
  description = "VMSS 관리자 사용자 이름"
  type        = string
  default     = "azureuser"
}

variable "vmss_admin_password" {
  description = "VMSS 관리자 비밀번호"
  type        = string
  sensitive   = true
}

variable "vmss_initial_instance_count" {
  description = "VMSS 초기 인스턴스 수"
  type        = number
  default     = 2
}

variable "vmss_min_instance_count" {
  description = "VMSS Auto Scaling 최소 인스턴스"
  type        = number
  default     = 2
}

variable "vmss_max_instance_count" {
  description = "VMSS Auto Scaling 최대 인스턴스"
  type        = number
  default     = 5
}

variable "vmss_scale_out_cpu_threshold" {
  description = "VMSS Scale-out CPU 임계값 (%)"
  type        = number
  default     = 70
}

variable "vmss_scale_in_cpu_threshold" {
  description = "VMSS Scale-in CPU 임계값 (%)"
  type        = number
  default     = 30
}

# ============================================================================
# Database 설정
# ============================================================================
variable "mysql_server_name" {
  description = "MySQL 서버 이름"
  type        = string
}

variable "mysql_admin_username" {
  description = "MySQL 관리자 사용자 이름"
  type        = string
  default     = "mysqladmin"
}

variable "mysql_admin_password" {
  description = "MySQL 관리자 비밀번호"
  type        = string
  sensitive   = true
}

variable "mysql_database_name" {
  description = "MySQL 데이터베이스 이름"
  type        = string
  default     = "appdb"
}

variable "mysql_sku_name" {
  description = "MySQL SKU"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "mysql_storage_size_gb" {
  description = "MySQL 스토리지 크기 (GB)"
  type        = number
  default     = 20
}

variable "mysql_backup_retention_days" {
  description = "MySQL 백업 보관 일수"
  type        = number
  default     = 7
}

variable "mysql_geo_redundant_backup_enabled" {
  description = "MySQL 지역 중복 백업 활성화"
  type        = bool
  default     = false
}

variable "mysql_enable_high_availability" {
  description = "MySQL 고가용성 활성화"
  type        = bool
  default     = false
}
