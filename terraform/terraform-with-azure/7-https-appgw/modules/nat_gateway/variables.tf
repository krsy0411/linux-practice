# ============================================================================
# NAT Gateway Module Variables
# ============================================================================

variable "resource_group_name" {
  description = "리소스 그룹 이름"
  type        = string
}

variable "location" {
  description = "Azure 리전"
  type        = string
}

variable "nat_gateway_name" {
  description = "NAT Gateway 이름"
  type        = string
  default     = "app-nat-gateway"
}

variable "nat_gateway_pip_name" {
  description = "NAT Gateway용 Public IP 이름"
  type        = string
  default     = "nat-gateway-pip"
}

variable "app_subnet_id" {
  description = "NAT Gateway를 연결할 App Subnet ID"
  type        = string
}

variable "idle_timeout_in_minutes" {
  description = <<-EOT
    NAT Gateway의 유휴 연결 타임아웃 (분)
    - 범위: 4~120분
    - 기본값: 4분
    - 장시간 연결 필요 시 증가 (예: 10분, 20분)
  EOT
  type        = number
  default     = 4

  validation {
    condition     = var.idle_timeout_in_minutes >= 4 && var.idle_timeout_in_minutes <= 120
    error_message = "idle_timeout_in_minutes는 4~120분 사이여야 합니다."
  }
}

variable "availability_zones" {
  description = <<-EOT
    Availability Zones 설정
    - ["1", "2", "3"]: 모든 존에 분산 (고가용성)
    - []: 존 지정 안함
    - Korea Central은 Availability Zones 지원
  EOT
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for zone in var.availability_zones : contains(["1", "2", "3"], zone)
    ])
    error_message = "Availability Zones는 '1', '2', '3' 중 하나여야 합니다."
  }
}

variable "tags" {
  description = "리소스에 적용할 태그"
  type        = map(string)
  default     = {}
}
