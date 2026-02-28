resource "azurerm_network_security_group" "web" {
  name                = "web-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_network_security_group" "db" {
  name                = "db-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
}

# -------------------------
# Web NSG Rules
# -------------------------

# HTTP 허용
resource "azurerm_network_security_rule" "web_http" {
  name                        = "Allow-HTTP"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = "*"
  destination_port_range      = "80"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.web.name
}

# -------------------------
# DB NSG Rules
# -------------------------

# MySQL 허용 (web subnet에서만)
resource "azurerm_network_security_rule" "db_mysql" {
  name                        = "Allow-MySQL"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = var.web_subnet_cidr
  destination_port_range      = "3306"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.db.name
}

# SSH 허용 (web subnet에서만)
resource "azurerm_network_security_rule" "db_ssh" {
  name                        = "Allow-SSH-from-Web"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = var.web_subnet_cidr
  destination_port_range      = "22"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.db.name
}

# -------------------------
# Subnet Association
# -------------------------

resource "azurerm_subnet_network_security_group_association" "web_assoc" {
  subnet_id                 = var.web_subnet_id
  network_security_group_id = azurerm_network_security_group.web.id
}

resource "azurerm_subnet_network_security_group_association" "db_assoc" {
  subnet_id                 = var.db_subnet_id
  network_security_group_id = azurerm_network_security_group.db.id
}