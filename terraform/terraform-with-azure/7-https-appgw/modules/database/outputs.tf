# ============================================================================
# Database Module Outputs
# ============================================================================

output "mysql_server_id" {
  description = "MySQL 서버 ID"
  value       = azurerm_mysql_flexible_server.this.id
}

output "mysql_server_name" {
  description = "MySQL 서버 이름"
  value       = azurerm_mysql_flexible_server.this.name
}

output "mysql_server_fqdn" {
  description = "MySQL 서버 FQDN (VNet 내부에서 사용)"
  value       = azurerm_mysql_flexible_server.this.fqdn
}

output "database_name" {
  description = "생성된 데이터베이스 이름"
  value       = azurerm_mysql_flexible_database.this.name
}

output "connection_string" {
  description = "MySQL 연결 문자열 (애플리케이션에서 사용)"
  value       = "Server=${azurerm_mysql_flexible_server.this.fqdn};Database=${azurerm_mysql_flexible_database.this.name};Uid=${var.admin_username};Pwd=<password>;SslMode=Required;"
  sensitive   = true
}
