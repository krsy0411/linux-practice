# ============================================================================
# NSG Module Outputs
# ============================================================================

output "appgw_nsg_id" {
  description = "Application Gateway NSG ID"
  value       = azurerm_network_security_group.appgw.id
}

output "app_nsg_id" {
  description = "App NSG ID"
  value       = azurerm_network_security_group.app.id
}

output "db_nsg_id" {
  description = "DB NSG ID"
  value       = azurerm_network_security_group.db.id
}
