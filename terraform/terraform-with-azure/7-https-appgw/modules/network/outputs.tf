# ============================================================================
# Network Module Outputs
# ============================================================================

output "resource_group_name" {
  description = "생성된 Resource Group 이름"
  value       = azurerm_resource_group.this.name
}

output "resource_group_id" {
  description = "생성된 Resource Group ID"
  value       = azurerm_resource_group.this.id
}

output "location" {
  description = "리소스가 배포된 Azure 리전"
  value       = azurerm_resource_group.this.location
}

output "vnet_id" {
  description = "생성된 VNet ID"
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "생성된 VNet 이름"
  value       = azurerm_virtual_network.this.name
}

# ============================================================================
# Application Gateway Subnet (Tier 1)
# ============================================================================
output "appgw_subnet_id" {
  description = "Application Gateway Subnet ID"
  value       = azurerm_subnet.appgw.id
}

output "appgw_subnet_name" {
  description = "Application Gateway Subnet 이름"
  value       = azurerm_subnet.appgw.name
}

# ============================================================================
# App Subnet (Tier 2)
# ============================================================================
output "app_subnet_id" {
  description = "App Subnet ID (VMSS 배치용)"
  value       = azurerm_subnet.app.id
}

output "app_subnet_name" {
  description = "App Subnet 이름"
  value       = azurerm_subnet.app.name
}

output "app_subnet_cidr" {
  description = "App Subnet CIDR (NSG 규칙에서 사용)"
  value       = var.app_subnet_cidr
}

# ============================================================================
# DB Subnet (Tier 3)
# ============================================================================
output "db_subnet_id" {
  description = "DB Subnet ID (데이터베이스용)"
  value       = azurerm_subnet.db.id
}

output "db_subnet_name" {
  description = "DB Subnet 이름"
  value       = azurerm_subnet.db.name
}

output "db_subnet_cidr" {
  description = "DB Subnet CIDR (NSG 규칙에서 사용)"
  value       = var.db_subnet_cidr
}
