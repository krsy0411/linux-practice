# ============================================================================
# Development Environment Outputs
# ============================================================================

# ============================================================================
# Network 정보
# ============================================================================
output "resource_group_name" {
  description = "생성된 Resource Group 이름"
  value       = module.network.resource_group_name
}

output "vnet_id" {
  description = "VNet ID"
  value       = module.network.vnet_id
}

# ============================================================================
# Application Gateway 정보
# ============================================================================
output "appgw_public_ip" {
  description = "Application Gateway Public IP 주소 (이 IP로 접속하세요)"
  value       = module.appgw.public_ip_address
}

output "appgw_fqdn" {
  description = "Application Gateway FQDN (DNS 레이블이 설정된 경우)"
  value       = module.appgw.public_ip_fqdn
}

output "appgw_https_url" {
  description = "HTTPS 접속 URL"
  value       = "https://${module.appgw.public_ip_address}"
}

# ============================================================================
# NAT Gateway 정보
# ============================================================================
output "nat_gateway_public_ip" {
  description = "NAT Gateway Public IP (VMSS가 이 IP로 인터넷에 나감)"
  value       = module.nat_gateway.nat_gateway_pip_address
}

# ============================================================================
# VMSS 정보
# ============================================================================
output "vmss_id" {
  description = "VMSS ID"
  value       = module.vmss.vmss_id
}

output "vmss_name" {
  description = "VMSS 이름"
  value       = module.vmss.vmss_name
}

# ============================================================================
# Database 정보
# ============================================================================
output "mysql_server_fqdn" {
  description = "MySQL 서버 FQDN (애플리케이션에서 사용)"
  value       = module.database.mysql_server_fqdn
}

output "mysql_database_name" {
  description = "MySQL 데이터베이스 이름"
  value       = module.database.database_name
}

output "mysql_connection_string" {
  description = "MySQL 연결 문자열"
  value       = module.database.connection_string
  sensitive   = true
}

# ============================================================================
# 접속 정보 요약
# ============================================================================
output "access_info" {
  description = "접속 정보 요약"
  value       = <<-EOT

    ╔══════════════════════════════════════════════════════════════════════╗
    ║                      접속 정보 (Access Information)                   ║
    ╚══════════════════════════════════════════════════════════════════════╝

    🌐 HTTPS 접속 URL:
       https://${module.appgw.public_ip_address}

    📊 Azure Portal에서 확인:
       - Application Gateway: ${module.appgw.appgw_name}
       - VMSS: ${module.vmss.vmss_name}
       - MySQL: ${module.database.mysql_server_name}

    🔍 다음 단계:
       1. Azure Portal에서 리소스 생성 확인
       2. HTTPS URL로 접속하여 테스트
       3. Auto Scaling 동작 확인 (CPU 부하 발생 시)
       4. MySQL 연결 테스트

    ⚠️  주의:
       - Self-signed 인증서 사용 시 브라우저 경고 발생
       - 프로덕션에서는 Let's Encrypt 또는 상용 인증서 사용 권장
  EOT
}
