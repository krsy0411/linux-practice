# ============================================================================
# NAT Gateway Module Outputs
# ============================================================================

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = azurerm_nat_gateway.this.id
}

output "nat_gateway_name" {
  description = "NAT Gateway 이름"
  value       = azurerm_nat_gateway.this.name
}

output "nat_gateway_pip_id" {
  description = "NAT Gateway Public IP ID"
  value       = azurerm_public_ip.nat.id
}

output "nat_gateway_pip_address" {
  description = "NAT Gateway Public IP 주소 (VM들이 이 IP로 인터넷에 나감)"
  value       = azurerm_public_ip.nat.ip_address
}
