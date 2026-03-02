# ============================================================================
# Application Gateway Module Variables
# ============================================================================

variable "resource_group_name" {
  description = "리소스 그룹 이름"
  type        = string
}

variable "location" {
  description = "Azure 리전"
  type        = string
}

variable "appgw_name" {
  description = "Application Gateway 이름"
  type        = string
  default     = "app-gateway"
}

variable "public_ip_name" {
  description = "Public IP 이름"
  type        = string
  default     = "appgw-public-ip"
}

variable "domain_name_label" {
  description = <<-EOT
    Public IP의 DNS 레이블 (선택사항)
    - 형식: <label>.<region>.cloudapp.azure.com
    - 예: myapp -> myapp.koreacentral.cloudapp.azure.com
  EOT
  type        = string
  default     = null
}

variable "appgw_subnet_id" {
  description = "Application Gateway가 배치될 Subnet ID"
  type        = string
}

variable "backend_pool_name" {
  description = "Backend Address Pool 이름"
  type        = string
  default     = "appgw-backend-pool"
}

# ============================================================================
# SKU 설정
# ============================================================================
variable "sku_name" {
  description = <<-EOT
    Application Gateway SKU
    - Standard_v2: 기본 기능
    - WAF_v2: Web Application Firewall 포함
  EOT
  type        = string
  default     = "Standard_v2"

  validation {
    condition     = contains(["Standard_v2", "WAF_v2"], var.sku_name)
    error_message = "SKU는 Standard_v2 또는 WAF_v2여야 합니다."
  }
}

variable "sku_tier" {
  description = "Application Gateway SKU Tier (sku_name과 동일해야 함)"
  type        = string
  default     = "Standard_v2"

  validation {
    condition     = contains(["Standard_v2", "WAF_v2"], var.sku_tier)
    error_message = "Tier는 Standard_v2 또는 WAF_v2여야 합니다."
  }
}

variable "capacity" {
  description = <<-EOT
    Application Gateway 인스턴스 수 (autoscale 비활성화 시)
    - 범위: 1~125
    - 권장: 2 이상 (고가용성)
  EOT
  type        = number
  default     = 2

  validation {
    condition     = var.capacity >= 1 && var.capacity <= 125
    error_message = "Capacity는 1~125 사이여야 합니다."
  }
}

# ============================================================================
# Auto Scaling 설정
# ============================================================================
variable "enable_autoscale" {
  description = "Auto Scaling 활성화 여부"
  type        = bool
  default     = false
}

variable "autoscale_min_capacity" {
  description = "Auto Scaling 최소 인스턴스 수"
  type        = number
  default     = 2

  validation {
    condition     = var.autoscale_min_capacity >= 0 && var.autoscale_min_capacity <= 125
    error_message = "최소 capacity는 0~125 사이여야 합니다."
  }
}

variable "autoscale_max_capacity" {
  description = "Auto Scaling 최대 인스턴스 수"
  type        = number
  default     = 10

  validation {
    condition     = var.autoscale_max_capacity >= 2 && var.autoscale_max_capacity <= 125
    error_message = "최대 capacity는 2~125 사이여야 합니다."
  }
}

# ============================================================================
# SSL/TLS 설정
# ============================================================================
variable "ssl_certificate_data" {
  description = <<-EOT
    SSL 인증서 데이터 (PFX 형식, base64 인코딩)

    Self-signed 인증서 생성 방법:
    openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes
    openssl pkcs12 -export -out certificate.pfx -inkey key.pem -in cert.pem
    cat certificate.pfx | base64
  EOT
  type        = string
  sensitive   = true
}

variable "ssl_certificate_password" {
  description = "SSL 인증서 비밀번호 (PFX 파일 생성 시 설정한 비밀번호)"
  type        = string
  sensitive   = true
}

variable "ssl_policy_name" {
  description = <<-EOT
    SSL Policy 이름
    - AppGwSslPolicy20220101: TLS 1.2+ (권장)
    - AppGwSslPolicy20170401S: TLS 1.2+ (강화)
    - AppGwSslPolicy20150501: TLS 1.0+ (레거시)
  EOT
  type        = string
  default     = "AppGwSslPolicy20220101"
}

# ============================================================================
# WAF 설정 (WAF_v2 SKU인 경우에만 사용)
# ============================================================================
variable "waf_mode" {
  description = <<-EOT
    WAF 모드
    - Detection: 탐지만 (로깅만 하고 차단 안함)
    - Prevention: 방어 (탐지 + 차단)
  EOT
  type        = string
  default     = "Prevention"

  validation {
    condition     = contains(["Detection", "Prevention"], var.waf_mode)
    error_message = "WAF 모드는 Detection 또는 Prevention이어야 합니다."
  }
}

variable "tags" {
  description = "리소스에 적용할 태그"
  type        = map(string)
  default     = {}
}
