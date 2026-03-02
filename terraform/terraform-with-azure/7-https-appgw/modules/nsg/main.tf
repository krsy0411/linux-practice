# ============================================================================
# NSG Module: 3-Tier Architecture 보안 규칙
# ============================================================================
# 보안 원칙:
# - Tier 1 (AppGW): 인터넷에서 80, 443 허용
# - Tier 2 (App): AppGW에서만 인바운드, DB로 아웃바운드, 인터넷은 NAT Gateway 통해서만
# - Tier 3 (DB): App에서만 3306 인바운드, 아웃바운드 차단
# ============================================================================

# ============================================================================
# Application Gateway Subnet NSG (Tier 1)
# ============================================================================
resource "azurerm_network_security_group" "appgw" {
  name                = "appgw-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = merge(
    var.tags,
    {
      Component = "nsg"
      Tier      = "presentation"
    }
  )
}

# Application Gateway 인바운드 규칙: HTTP (80)
resource "azurerm_network_security_rule" "appgw_http" {
  name                        = "allow-http"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.appgw.name
}

# Application Gateway 인바운드 규칙: HTTPS (443)
resource "azurerm_network_security_rule" "appgw_https" {
  name                        = "allow-https"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.appgw.name
}

# Application Gateway 인바운드 규칙: 관리 포트 (Azure 인프라용)
# - Application Gateway가 정상 작동하려면 필수
# - 65200-65535: Azure 인프라가 상태 확인 및 관리에 사용
resource "azurerm_network_security_rule" "appgw_management" {
  name                        = "allow-appgw-management"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "65200-65535"
  source_address_prefix       = "GatewayManager"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.appgw.name
}

# Application Gateway Subnet에 NSG 연결
resource "azurerm_subnet_network_security_group_association" "appgw" {
  subnet_id                 = var.appgw_subnet_id
  network_security_group_id = azurerm_network_security_group.appgw.id
}

# ============================================================================
# App Subnet NSG (Tier 2)
# ============================================================================
resource "azurerm_network_security_group" "app" {
  name                = "app-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = merge(
    var.tags,
    {
      Component = "nsg"
      Tier      = "application"
    }
  )
}

# App 인바운드 규칙: Application Gateway에서만 허용
resource "azurerm_network_security_rule" "app_from_appgw" {
  name                        = "allow-from-appgw"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = var.appgw_subnet_cidr
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.app.name
}

# App 아웃바운드 규칙: Database Subnet으로 허용
resource "azurerm_network_security_rule" "app_to_db" {
  name                        = "allow-to-db"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3306"
  source_address_prefix       = "*"
  destination_address_prefix  = var.db_subnet_cidr
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.app.name
}

# App 아웃바운드 규칙: 인터넷 접근 허용 (NAT Gateway를 통해)
# - NSG는 허용하지만, 실제 라우팅은 NAT Gateway를 통해 이루어짐
# - NAT Gateway가 없으면 아웃바운드 불가
# - NAT Gateway를 통해 나가므로 인바운드는 여전히 차단됨
resource "azurerm_network_security_rule" "app_to_internet" {
  name                        = "allow-to-internet-via-nat"
  priority                    = 110
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "Internet"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.app.name
}

# App Subnet에 NSG 연결
resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = var.app_subnet_id
  network_security_group_id = azurerm_network_security_group.app.id
}

# ============================================================================
# DB Subnet NSG (Tier 3)
# ============================================================================
resource "azurerm_network_security_group" "db" {
  name                = "db-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = merge(
    var.tags,
    {
      Component = "nsg"
      Tier      = "data"
    }
  )
}

# DB 인바운드 규칙: App Subnet에서만 MySQL 접근 허용
resource "azurerm_network_security_rule" "db_from_app" {
  name                        = "allow-mysql-from-app"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3306"
  source_address_prefix       = var.app_subnet_cidr
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.db.name
}

# DB 아웃바운드 규칙: 인터넷으로의 모든 아웃바운드 차단
# - 데이터베이스는 외부로 나가는 연결이 필요 없음
resource "azurerm_network_security_rule" "db_deny_outbound" {
  name                        = "deny-internet-outbound"
  priority                    = 4096
  direction                   = "Outbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "Internet"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.db.name
}

# DB Subnet에 NSG 연결
resource "azurerm_subnet_network_security_group_association" "db" {
  subnet_id                 = var.db_subnet_id
  network_security_group_id = azurerm_network_security_group.db.id
}
