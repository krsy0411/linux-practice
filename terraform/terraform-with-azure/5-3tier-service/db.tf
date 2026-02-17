# nic
resource "azurerm_network_interface" "db_nic" {
  name                = "db-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.db.id
    private_ip_address_allocation = "Dynamic"
  }
}

# db vm
resource "azurerm_linux_virtual_machine" "db_vm" {
  name                = "db-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.db_nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(<<EOF
#!/bin/bash

apt update
apt install -y mysql-server

systemctl enable mysql
systemctl start mysql

# MySQL 외부 접속 허용 설정
sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf

systemctl restart mysql

# DB 및 사용자 생성
mysql -e "CREATE DATABASE appdb;"
mysql -e "CREATE USER 'appuser'@'10.10.2.%' IDENTIFIED BY 'password123';"
mysql -e "GRANT ALL PRIVILEGES ON appdb.* TO 'appuser'@'10.10.2.%';"
mysql -e "FLUSH PRIVILEGES;"

EOF
)
  
}
