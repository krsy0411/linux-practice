# ============================================================================
# Application Gateway Module: HTTPS 로드 밸런서 (Tier 1)
# ============================================================================
# - Layer 7 (HTTP/HTTPS) 로드 밸런서
# - SSL/TLS 종단 (TLS Termination)
# - URL 기반 라우팅
# - WAF (Web Application Firewall) 지원
# ============================================================================

# ============================================================================
# Public IP for Application Gateway
# ============================================================================
# - SKU는 Standard여야 함 (Application Gateway v2는 Standard만 지원)
# - allocation_method는 Static
resource "azurerm_public_ip" "appgw" {
  name                = var.public_ip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = var.domain_name_label

  tags = merge(
    var.tags,
    {
      Component = "appgw-public-ip"
    }
  )
}

# ============================================================================
# Application Gateway
# ============================================================================
resource "azurerm_application_gateway" "this" {
  name                = var.appgw_name
  location            = var.location
  resource_group_name = var.resource_group_name

  # ========================================
  # SKU 설정
  # ========================================
  # - Standard_v2: 기본 기능
  # - WAF_v2: Web Application Firewall 포함
  # - capacity: 인스턴스 수 (1~125)
  # - autoscale: 자동 확장 (min/max 인스턴스)
  sku {
    name     = var.sku_name
    tier     = var.sku_tier
    capacity = var.enable_autoscale ? null : var.capacity
  }

  # 자동 확장 설정 (선택사항)
  dynamic "autoscale_configuration" {
    for_each = var.enable_autoscale ? [1] : []
    content {
      min_capacity = var.autoscale_min_capacity
      max_capacity = var.autoscale_max_capacity
    }
  }

  # ========================================
  # Gateway IP Configuration
  # ========================================
  # - Application Gateway가 배치될 서브넷
  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = var.appgw_subnet_id
  }

  # ========================================
  # Frontend IP Configuration
  # ========================================
  # - Public IP 연결
  frontend_ip_configuration {
    name                 = "appgw-frontend-ip"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  # ========================================
  # Frontend Port: HTTP (80)
  # ========================================
  frontend_port {
    name = "http-port"
    port = 80
  }

  # ========================================
  # Frontend Port: HTTPS (443)
  # ========================================
  frontend_port {
    name = "https-port"
    port = 443
  }

  # ========================================
  # Backend Address Pool
  # ========================================
  # - VMSS의 인스턴스들이 자동으로 추가됨
  # - 고정 IP 또는 FQDN도 추가 가능
  backend_address_pool {
    name = var.backend_pool_name
  }

  # ========================================
  # Backend HTTP Settings
  # ========================================
  # - Backend (VMSS)로 전달할 때의 프로토콜/포트 설정
  # - cookie_based_affinity: 세션 고정 (Enabled/Disabled)
  # - request_timeout: 백엔드 응답 대기 시간 (초)
  # - pick_host_name_from_backend_address: 백엔드 주소에서 호스트명 가져오기
  backend_http_settings {
    name                                = "appgw-backend-http-settings"
    cookie_based_affinity               = "Disabled"
    port                                = 80
    protocol                            = "Http"
    request_timeout                     = 60
    probe_name                          = "appgw-health-probe"
    pick_host_name_from_backend_address = true
  }

  # ========================================
  # Health Probe
  # ========================================
  # - 백엔드 인스턴스의 상태 확인
  # - interval: 체크 간격 (초)
  # - timeout: 응답 대기 시간 (초)
  # - unhealthy_threshold: 실패 횟수 임계값
  # - pick_host_name_from_backend_http_settings: Backend HTTP Settings의 호스트명 사용
  probe {
    name                                      = "appgw-health-probe"
    protocol                                  = "Http"
    path                                      = "/"
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true

    match {
      status_code = ["200-399"]
    }
  }

  # ========================================
  # HTTP Listener
  # ========================================
  # - HTTP 요청 수신
  # - HTTP to HTTPS 리다이렉션에 사용
  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "appgw-frontend-ip"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  # ========================================
  # HTTPS Listener
  # ========================================
  # - HTTPS 요청 수신
  # - SSL 인증서 필요
  http_listener {
    name                           = "https-listener"
    frontend_ip_configuration_name = "appgw-frontend-ip"
    frontend_port_name             = "https-port"
    protocol                       = "Https"
    ssl_certificate_name           = "appgw-ssl-cert"
  }

  # ========================================
  # SSL Certificate
  # ========================================
  # - PFX 형식의 인증서 필요
  # - data: base64 인코딩된 PFX 파일
  # - password: PFX 파일의 비밀번호
  ssl_certificate {
    name     = "appgw-ssl-cert"
    data     = var.ssl_certificate_data
    password = var.ssl_certificate_password
  }

  # ========================================
  # Request Routing Rule: HTTP to HTTPS 리다이렉션
  # ========================================
  request_routing_rule {
    name                        = "http-to-https-redirect"
    rule_type                   = "Basic"
    http_listener_name          = "http-listener"
    redirect_configuration_name = "http-to-https"
    priority                    = 100
  }

  # ========================================
  # Redirect Configuration: HTTP to HTTPS
  # ========================================
  redirect_configuration {
    name                 = "http-to-https"
    redirect_type        = "Permanent"
    target_listener_name = "https-listener"
    include_path         = true
    include_query_string = true
  }

  # ========================================
  # Request Routing Rule: HTTPS
  # ========================================
  request_routing_rule {
    name                       = "https-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "https-listener"
    backend_address_pool_name  = var.backend_pool_name
    backend_http_settings_name = "appgw-backend-http-settings"
    priority                   = 200
  }

  # ========================================
  # WAF Configuration (WAF_v2 SKU인 경우에만)
  # ========================================
  dynamic "waf_configuration" {
    for_each = var.sku_tier == "WAF_v2" ? [1] : []
    content {
      enabled                  = true
      firewall_mode            = var.waf_mode
      rule_set_type            = "OWASP"
      rule_set_version         = "3.2"
      file_upload_limit_mb     = 100
      request_body_check       = true
      max_request_body_size_kb = 128
    }
  }

  # ========================================
  # SSL Policy
  # ========================================
  # - 최신 TLS 버전만 허용 (보안 강화)
  # - policy_type: Predefined 또는 Custom
  ssl_policy {
    policy_type = "Predefined"
    policy_name = var.ssl_policy_name
  }

  tags = merge(
    var.tags,
    {
      Component = "application-gateway"
      Tier      = "presentation"
    }
  )
}
