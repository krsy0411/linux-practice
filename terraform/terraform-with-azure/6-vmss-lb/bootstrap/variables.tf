variable "resource_group_name" {
  description = "Name of the resource group for Terraform state"
  type        = string
  default     = "tfstate-rg-for-vmss-lb-syungg"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "Korea Central"
}

variable "storage_account_name" {
  description = "Name of the storage account for Terraform state (must be globally unique)"
  type        = string
  default     = "tfstateforvmsslb"
}

variable "storage_container_name" {
  description = "Name of the storage container for Terraform state"
  type        = string
  default     = "tfstate-container-for-vmss-lb-syungg"
}
