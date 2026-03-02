# ============================================================================
# Application Gateway Module Outputs
# ============================================================================

output "appgw_id" {
  description = "Application Gateway ID"
  value       = azurerm_application_gateway.this.id
}

output "appgw_name" {
  description = "Application Gateway 이름"
  value       = azurerm_application_gateway.this.name
}

output "public_ip_id" {
  description = "Public IP ID"
  value       = azurerm_public_ip.appgw.id
}

output "public_ip_address" {
  description = "Public IP 주소 (이 IP로 접속)"
  value       = azurerm_public_ip.appgw.ip_address
}

output "public_ip_fqdn" {
  description = "Public IP FQDN (DNS 레이블이 설정된 경우)"
  value       = azurerm_public_ip.appgw.fqdn
}

output "backend_pool_id" {
  description = "Backend Address Pool ID (VMSS 연결에 사용)"
  value       = tolist(azurerm_application_gateway.this.backend_address_pool)[0].id
}

output "backend_pool_name" {
  description = "Backend Address Pool 이름"
  value       = tolist(azurerm_application_gateway.this.backend_address_pool)[0].name
}
