# Backend 변수 정의
variable "backend_resource_group_name" {
  description = "Resource group name for Terraform state storage"
  type        = string
  default     = "tfstate-rg-for-vmss-lb-syungg"
}

variable "backend_storage_account_name" {
  description = "Storage account name for Terraform state"
  type        = string
  default     = "tfstateforvmsslb"
}

variable "backend_container_name" {
  description = "Container name for Terraform state"
  type        = string
  default     = "tfstate-container-for-vmss-lb-syungg"
}

variable "backend_key" {
  description = "State file key/path in the container"
  type        = string
  default     = "dev.tfstate"
}

# 환경 변수 정의
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "Korea Central"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "vmss-lb-rg-dev"
}
