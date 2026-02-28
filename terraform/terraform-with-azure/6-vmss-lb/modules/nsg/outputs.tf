output "web_nsg_id" {
  value = azurerm_network_security_group.web.id
}

output "db_nsg_id" {
  value = azurerm_network_security_group.db.id
}