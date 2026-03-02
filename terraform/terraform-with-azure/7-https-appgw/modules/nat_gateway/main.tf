# ============================================================================
# NAT Gateway Module: 아웃바운드 인터넷 연결을 위한 NAT Gateway
# ============================================================================
# 목적:
# - App Subnet의 VM들이 인터넷으로 아웃바운드 연결 (패키지 다운로드, 업데이트 등)
# - 인바운드 연결은 차단 (보안 강화)
# - Public IP를 통해 나가지만, 들어오는 연결은 불가능
#
# NAT Gateway vs Public IP on VM:
# - NAT Gateway: 여러 VM이 하나의 Public IP 공유, 보안성 높음
# - Public IP on VM: 각 VM마다 Public IP, 인바운드도 가능 (보안 취약)
# ============================================================================

# ============================================================================
# Public IP for NAT Gateway
# ============================================================================
# - SKU는 Standard여야 함 (Basic은 NAT Gateway와 호환 안됨)
# - allocation_method는 Static이어야 함
# - zones: Availability Zones 지정 (고가용성)
# ============================================================================
resource "azurerm_public_ip" "nat" {
  name                = var.nat_gateway_pip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  # Availability Zones 설정 (선택사항)
  # - 한국 리전은 Availability Zones를 지원함
  # - zones = ["1", "2", "3"]: 모든 존에 분산 (권장)
  # - zones = []: 존 지정 안함 (기본 설정)
  zones = var.availability_zones

  tags = merge(
    var.tags,
    {
      Component = "nat-gateway-pip"
      Purpose   = "outbound-internet"
    }
  )
}

# ============================================================================
# NAT Gateway
# ============================================================================
# - SKU: Standard (현재 유일한 옵션)
# - idle_timeout_in_minutes: 유휴 연결 타임아웃 (4~120분, 기본 4분)
# - zones: Public IP와 동일한 존에 배치
# ============================================================================
resource "azurerm_nat_gateway" "this" {
  name                    = var.nat_gateway_name
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = var.idle_timeout_in_minutes
  zones                   = var.availability_zones

  tags = merge(
    var.tags,
    {
      Component = "nat-gateway"
      Purpose   = "outbound-internet"
    }
  )
}

# ============================================================================
# NAT Gateway와 Public IP 연결
# ============================================================================
# - NAT Gateway는 하나 이상의 Public IP를 가질 수 있음
# - 트래픽 증가 시 여러 Public IP 추가 가능
# ============================================================================
resource "azurerm_nat_gateway_public_ip_association" "this" {
  nat_gateway_id       = azurerm_nat_gateway.this.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

# ============================================================================
# NAT Gateway를 App Subnet에 연결
# ============================================================================
# - 이 서브넷의 모든 아웃바운드 트래픽은 NAT Gateway를 통해 나감
# - 인바운드 트래픽은 NAT Gateway를 통과하지 않음 (Application Gateway 사용)
# ============================================================================
resource "azurerm_subnet_nat_gateway_association" "app" {
  subnet_id      = var.app_subnet_id
  nat_gateway_id = azurerm_nat_gateway.this.id
}
