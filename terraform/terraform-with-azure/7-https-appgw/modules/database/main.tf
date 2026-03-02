# ============================================================================
# Database Module: Azure Database for MySQL Flexible Server (Tier 3)
# ============================================================================
# - MySQL 8.0
# - Private Access (VNet 통합)
# - App Subnet에서만 접근 가능 (NSG로 제어)
# - 자동 백업 및 고가용성 옵션
# ============================================================================

# ============================================================================
# Private DNS Zone for MySQL
# ============================================================================
# - MySQL Flexible Server의 Private Access를 위한 DNS Zone
# - VNet 내에서 MySQL 서버에 Private IP로 접근
resource "azurerm_private_dns_zone" "mysql" {
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = var.resource_group_name

  tags = merge(
    var.tags,
    {
      Component = "private-dns"
      Purpose   = "mysql-private-access"
    }
  )
}

# ============================================================================
# Private DNS Zone - VNet Link
# ============================================================================
# - Private DNS Zone을 VNet에 연결
# - VNet 내에서 DNS 조회 가능
resource "azurerm_private_dns_zone_virtual_network_link" "mysql" {
  name                  = "${var.mysql_server_name}-vnet-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.mysql.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false

  tags = var.tags
}

# ============================================================================
# MySQL Flexible Server
# ============================================================================
# SKU 형식: [Tier]_[Family]_[Cores]
# - B_Standard_B1ms: Burstable, 1 vCore, 2GB RAM (개발/테스트)
# - GP_Standard_D2ds_v4: General Purpose, 2 vCore, 8GB RAM (프로덕션)
# - MO_Standard_E4ds_v4: Memory Optimized, 4 vCore, 32GB RAM (고성능)
#
# 네트워크 보안:
# - delegated_subnet_id: MySQL이 배치될 전용 서브넷
# - private_dns_zone_id: Private DNS Zone 연결
# - Public Access 없음 (VNet 내부에서만 접근)
# - NSG로 App Subnet에서만 3306 포트 접근 허용
resource "azurerm_mysql_flexible_server" "this" {
  name                   = var.mysql_server_name
  resource_group_name    = var.resource_group_name
  location               = var.location
  administrator_login    = var.admin_username
  administrator_password = var.admin_password

  version = "8.0.21"
  sku_name = var.sku_name

  # VNet Integration (Private Access)
  delegated_subnet_id = var.db_subnet_id
  private_dns_zone_id = azurerm_private_dns_zone.mysql.id

  # 스토리지 설정
  storage {
    size_gb           = var.storage_size_gb
    auto_grow_enabled = true
  }

  # 백업 설정
  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled

  # 고가용성 설정 (선택사항)
  dynamic "high_availability" {
    for_each = var.enable_high_availability ? [1] : []
    content {
      mode = "ZoneRedundant"
    }
  }

  tags = merge(
    var.tags,
    {
      Component = "mysql"
      Tier      = "data"
    }
  )

  # Azure API 제약사항: VNet-DNS Zone 연결이 완료된 후 MySQL 생성 필요
  # 암묵적 의존성만으로는 타이밍 보장 불가하므로 명시적 의존성 사용
  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.mysql
  ]
}

# ============================================================================
# MySQL 보안 설정: SSL/TLS 필수
# ============================================================================
resource "azurerm_mysql_flexible_server_configuration" "require_secure_transport" {
  name                = "require_secure_transport"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.this.name
  value               = "ON"
}

# ============================================================================
# MySQL Database 생성
# ============================================================================
resource "azurerm_mysql_flexible_database" "this" {
  name                = var.database_name
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.this.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}
