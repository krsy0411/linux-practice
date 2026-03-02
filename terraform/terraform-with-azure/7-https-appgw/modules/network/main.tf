# ============================================================================
# Network Module: 3-Tier Architecture용 VNet 및 서브넷 구성
# ============================================================================
# 아키텍처:
# - Tier 1 (Presentation): Application Gateway Subnet
# - Tier 2 (Application): App Subnet (VMSS)
# - Tier 3 (Data): DB Subnet (Azure Database)
# ============================================================================

# ============================================================================
# Resource Group
# ============================================================================
resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location

  tags = merge(
    var.tags,
    {
      Component = "resource-group"
    }
  )
}

# ============================================================================
# Virtual Network
# ============================================================================
resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [var.vnet_cidr]

  tags = merge(
    var.tags,
    {
      Component = "vnet"
    }
  )
}

# ============================================================================
# Application Gateway Subnet (Tier 1: Presentation Layer)
# ============================================================================
# - Application Gateway 전용 서브넷
# - Public IP를 통해 인터넷 트래픽을 수신
# - HTTPS 종단(TLS Termination) 수행
# - 최소 /27 (32개 IP) 권장
# ============================================================================
resource "azurerm_subnet" "appgw" {
  name                 = "appgw-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.appgw_subnet_cidr]
}

# ============================================================================
# App Subnet (Tier 2: Application Layer)
# ============================================================================
# - VMSS의 VM 인스턴스들이 배치됨
# - Private IP만 사용 (외부 접근 불가)
# - Application Gateway에서만 트래픽 수신
# - Database Subnet으로 아웃바운드 연결 가능
# ============================================================================
resource "azurerm_subnet" "app" {
  name                 = "app-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.app_subnet_cidr]
}

# ============================================================================
# DB Subnet (Tier 3: Data Layer)
# ============================================================================
# - Azure Database for MySQL/PostgreSQL 배치
# - 완전한 Private 서브넷 (인터넷 접근 불가)
# - App Subnet에서만 접근 가능
# - delegation: MySQL Flexible Server 전용 서브넷으로 설정
# ============================================================================
resource "azurerm_subnet" "db" {
  name                 = "db-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.db_subnet_cidr]

  # MySQL Flexible Server를 위한 Subnet Delegation (필수)
  # - 이 서브넷은 MySQL Flexible Server 전용으로 사용됨
  # - 다른 리소스를 배치할 수 없음
  delegation {
    name = "mysql-delegation"

    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}
