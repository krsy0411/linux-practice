# ============================================================================
# VMSS Module Variables
# ============================================================================

variable "resource_group_name" {
  description = "리소스 그룹 이름"
  type        = string
}

variable "location" {
  description = "Azure 리전"
  type        = string
}

variable "vmss_name" {
  description = "VMSS 이름"
  type        = string
  default     = "app-vmss"
}

variable "subnet_id" {
  description = "VMSS를 배치할 Subnet ID (App Subnet)"
  type        = string
}

variable "backend_pool_ids" {
  description = "Application Gateway Backend Pool ID 목록"
  type        = list(string)
}

variable "vm_sku" {
  description = <<-EOT
    VM 크기 (SKU)
    - Standard_B1s: 1 vCPU, 1GB RAM (테스트용)
    - Standard_B2s: 2 vCPU, 4GB RAM (소규모)
    - Standard_D2s_v3: 2 vCPU, 8GB RAM (프로덕션)
  EOT
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "VM 관리자 사용자 이름"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = <<-EOT
    VM 관리자 비밀번호
    - 최소 12자 이상
    - 대문자, 소문자, 숫자, 특수문자 포함
    - 실무에서는 SSH 키 사용 권장
  EOT
  type        = string
  sensitive   = true
}

variable "initial_instance_count" {
  description = "초기 인스턴스 수"
  type        = number
  default     = 2

  validation {
    condition     = var.initial_instance_count >= 1 && var.initial_instance_count <= 100
    error_message = "인스턴스 수는 1~100 사이여야 합니다."
  }
}

variable "min_instance_count" {
  description = "Auto Scaling 최소 인스턴스 수"
  type        = number
  default     = 2

  validation {
    condition     = var.min_instance_count >= 1
    error_message = "최소 인스턴스 수는 1 이상이어야 합니다."
  }
}

variable "max_instance_count" {
  description = "Auto Scaling 최대 인스턴스 수"
  type        = number
  default     = 5

  validation {
    condition     = var.max_instance_count >= 1 && var.max_instance_count <= 100
    error_message = "최대 인스턴스 수는 1~100 사이여야 합니다."
  }
}

variable "scale_out_cpu_threshold" {
  description = "Scale-out을 트리거하는 CPU 임계값 (%)"
  type        = number
  default     = 70

  validation {
    condition     = var.scale_out_cpu_threshold > 0 && var.scale_out_cpu_threshold <= 100
    error_message = "CPU 임계값은 0~100 사이여야 합니다."
  }
}

variable "scale_in_cpu_threshold" {
  description = "Scale-in을 트리거하는 CPU 임계값 (%)"
  type        = number
  default     = 30

  validation {
    condition     = var.scale_in_cpu_threshold > 0 && var.scale_in_cpu_threshold <= 100
    error_message = "CPU 임계값은 0~100 사이여야 합니다."
  }
}

variable "tags" {
  description = "리소스에 적용할 태그"
  type        = map(string)
  default     = {}
}
