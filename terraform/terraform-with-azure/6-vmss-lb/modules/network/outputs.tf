output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "web_subnet_id" {
  value = azurerm_subnet.web.id
}

output "db_subnet_id" {
  value = azurerm_subnet.db.id
}