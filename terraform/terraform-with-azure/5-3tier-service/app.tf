# nic
resource "azurerm_network_interface" "app_nic" {
  name                = "app-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.app.id
    private_ip_address_allocation = "Dynamic"
  }
}

# app vm
resource "azurerm_linux_virtual_machine" "app_vm" {
  name                = "app-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.app_nic.id
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
apt install -y python3-pip
pip3 install flask mysql-connector-python

cat <<EOT > /home/${var.admin_username}/app.py
from flask import Flask
import mysql.connector

app = Flask(__name__)

@app.route("/")
def hello():
    conn = mysql.connector.connect(
        host="10.10.3.4",
        user="appuser",
        password="password123",
        database="appdb"
    )
    cursor = conn.cursor()
    cursor.execute("SELECT 1")
    result = cursor.fetchone()
    return f"DB Connected: {result}"

app.run(host="0.0.0.0", port=5000)
EOT

chown ${var.admin_username}:${var.admin_username} /home/${var.admin_username}/app.py
nohup python3 /home/${var.admin_username}/app.py &
EOF
  )
}

