# ============================================================================
# VMSS Module: 애플리케이션 서버 (Tier 2)
# ============================================================================
# - Ubuntu 22.04 LTS 기반
# - Nginx 웹 서버 자동 설치 (cloud-init)
# - Application Gateway Backend Pool에 자동 등록
# - Auto Scaling 설정 (CPU 기반)
# ============================================================================

# ============================================================================
# Linux Virtual Machine Scale Set
# ============================================================================
resource "azurerm_linux_virtual_machine_scale_set" "this" {
  name                = var.vmss_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.vm_sku
  instances           = var.initial_instance_count

  # 관리자 계정 설정
  admin_username                  = var.admin_username
  disable_password_authentication = false
  admin_password                  = var.admin_password

  # OS 이미지: Ubuntu 22.04 LTS
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  # OS 디스크 설정
  os_disk {
    storage_account_type = "Standard_LRS"  # Standard_LRS, Premium_LRS, StandardSSD_LRS
    caching              = "ReadWrite"
  }

  # 네트워크 인터페이스 설정
  network_interface {
    name    = "vmss-nic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = var.subnet_id

      # Application Gateway Backend Pool에 자동 등록
      # - VMSS의 모든 인스턴스가 이 백엔드 풀에 추가됨
      # - Application Gateway가 이 풀의 인스턴스들로 트래픽 분산
      application_gateway_backend_address_pool_ids = var.backend_pool_ids
    }
  }

  # Cloud-init을 통한 VM 초기화
  # - 패키지 업데이트
  # - Nginx 설치 및 시작
  # - 커스텀 HTML 페이지 생성
  custom_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
    hostname = var.vmss_name
  }))

  tags = merge(
    var.tags,
    {
      Component = "vmss"
      Tier      = "application"
    }
  )
}

# ============================================================================
# Auto Scaling 설정
# ============================================================================
# - CPU 사용률 기반 자동 확장/축소
# - 최소/최대 인스턴스 수 설정
# - Cooldown 기간 설정 (빈번한 스케일링 방지)
# ============================================================================
resource "azurerm_monitor_autoscale_setting" "this" {
  name                = "${var.vmss_name}-autoscale"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.this.id

  profile {
    name = "default-profile"

    capacity {
      default = var.initial_instance_count
      minimum = var.min_instance_count
      maximum = var.max_instance_count
    }

    # Scale-out 규칙: CPU 70% 이상 시 인스턴스 추가
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.this.id
        time_grain         = "PT1M"   # 1분 단위로 메트릭 수집
        statistic          = "Average"
        time_window        = "PT5M"   # 5분 동안의 평균
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = var.scale_out_cpu_threshold
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"  # 5분 대기 (빈번한 스케일링 방지)
      }
    }

    # Scale-in 규칙: CPU 30% 이하 시 인스턴스 제거
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.this.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = var.scale_in_cpu_threshold
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Component = "autoscale"
      Tier      = "application"
    }
  )
}
