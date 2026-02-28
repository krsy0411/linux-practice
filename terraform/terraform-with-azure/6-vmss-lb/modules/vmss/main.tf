resource "azurerm_linux_virtual_machine_scale_set" "this" {
  name                = "web-vmss"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard_B1s"
  instances           = 2 # 초기 인스턴스 수는 2로 설정, 필요에 따라 조정 가능
  admin_username      = "azureuser"

  disable_password_authentication = false
  admin_password                  = "Password1234!"

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "vmss-nic"
    primary = true

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = var.subnet_id
      load_balancer_backend_address_pool_ids = [var.backend_pool_id]
    }
  }

  custom_data = base64encode(<<EOF
#cloud-config
package_update: true
packages:
  - nginx

write_files:
  - path: /var/www/html/index.html
    owner: root:root
    permissions: '0644'
    content: |
      <h1>VMSS Web Server</h1>

runcmd:
  # Use noninteractive frontend and retry installs; log output for debugging
  - [ bash, -lc, "export DEBIAN_FRONTEND=noninteractive; apt-get update -y >> /var/log/cc_bootstrap.log 2>&1 || true" ]
  - [ bash, -lc, "export DEBIAN_FRONTEND=noninteractive; (apt-get install -y nginx >> /var/log/cc_bootstrap.log 2>&1) || (sleep 10 && apt-get install -y nginx >> /var/log/cc_bootstrap.log 2>&1) || true" ]
  - [ bash, -lc, "systemctl enable nginx >> /var/log/cc_bootstrap.log 2>&1 || true" ]
  - [ bash, -lc, "systemctl start nginx >> /var/log/cc_bootstrap.log 2>&1 || (sleep 5 && systemctl start nginx >> /var/log/cc_bootstrap.log 2>&1) || true" ]
  - [ bash, -lc, "echo \"[$(date -u +%Y-%m-%dT%H:%M:%SZ)] cloud-init runcmd finished\" >> /var/log/cc_bootstrap.log" ]

final_message: "Cloud-init finished"
EOF
  )
}

# Autoscale 설정
resource "azurerm_monitor_autoscale_setting" "this" {
  name                = "vmss-autoscale"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.this.id

  profile {
    name = "default-profile"
    
    # 최소 2, 최대 5, 기본 2 인스턴스로 설정
    capacity {
      default = 2
      minimum = 2
      maximum = 5
    }

    # CPU 사용률이 70% 이상이면 인스턴스 1개 증가
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.this.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    # 30% 이하이면 인스턴스 1개 감소
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.this.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 30
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }
}