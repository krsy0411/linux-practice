# Azure Portal 확인 가이드

## 📋 목차
1. [Resource Group 확인](#resource-group-확인)
2. [Virtual Network 확인](#virtual-network-확인)
3. [Network Security Groups 확인](#network-security-groups-확인)
4. [NAT Gateway 확인](#nat-gateway-확인)
5. [Application Gateway 확인](#application-gateway-확인)
6. [VMSS 확인](#vmss-확인)
7. [MySQL Database 확인](#mysql-database-확인)
8. [모니터링 및 로그](#모니터링-및-로그)

---

## Resource Group 확인

### Portal 경로
```
Home → Resource groups → dev-rg
```

### Terraform 코드와 비교
```terraform
# modules/network/main.tf
resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name  # "dev-rg"
  location = var.location             # "Korea Central"
}
```

### Portal에서 확인할 항목

#### 1. 기본 정보
- **Name**: `dev-rg`
- **Location**: `Korea Central`
- **Subscription**: 현재 사용 중인 구독

#### 2. Tags
```
Environment = dev
Project     = 7-https-appgw
ManagedBy   = terraform
CreatedDate = <생성 날짜>
```

#### 3. 포함된 리소스 (약 20~25개)
```
✓ Virtual Network: dev-vnet
✓ Subnets: appgw-subnet, app-subnet, db-subnet
✓ Network Security Groups: appgw-nsg, app-nsg, db-nsg
✓ NAT Gateway: dev-vnet-nat-gw
✓ Public IPs: appgw-public-ip, nat-gateway-pip
✓ Application Gateway: dev-appgw
✓ VMSS: dev-vmss
✓ MySQL Server: dev-mysql-unique123
✓ Private DNS Zone: privatelink.mysql.database.azure.com
```

**스크린샷 포인트:**
- Overview 탭에서 리소스 목록 확인
- 각 리소스의 Status가 "Succeeded"인지 확인

---

## Virtual Network 확인

### Portal 경로
```
Resource groups → dev-rg → dev-vnet
```

### Terraform 코드와 비교
```terraform
# modules/network/main.tf
resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name      # "dev-vnet"
  location            = "Korea Central"
  resource_group_name = "dev-rg"
  address_space       = [var.vnet_cidr]    # ["10.10.0.0/16"]
}
```

### Portal에서 확인할 항목

#### 1. Address Space
```
Portal: VNet → Settings → Address space

확인:
- Address range: 10.10.0.0/16
- Available IPs: 65,536
```

**Terraform 출력 비교:**
```bash
terraform output vnet_id
# /subscriptions/.../resourceGroups/dev-rg/providers/Microsoft.Network/virtualNetworks/dev-vnet
```

#### 2. Subnets
```
Portal: VNet → Settings → Subnets

확인:
┌─────────────────┬─────────────────┬───────────┬────────────────┐
│ Name            │ Address Range   │ Available │ Connected To   │
├─────────────────┼─────────────────┼───────────┼────────────────┤
│ appgw-subnet    │ 10.10.0.0/27    │ 27        │ App Gateway    │
│ app-subnet      │ 10.10.1.0/24    │ 251       │ VMSS + NAT GW  │
│ db-subnet       │ 10.10.2.0/24    │ 251       │ MySQL Server   │
└─────────────────┴─────────────────┴───────────┴────────────────┘
```

**Terraform 코드 비교:**
```terraform
# appgw-subnet
resource "azurerm_subnet" "appgw" {
  name                 = "appgw-subnet"
  address_prefixes     = ["10.10.0.0/27"]  # 32 IPs
}

# app-subnet
resource "azurerm_subnet" "app" {
  name                 = "app-subnet"
  address_prefixes     = ["10.10.1.0/24"]  # 256 IPs
}

# db-subnet
resource "azurerm_subnet" "db" {
  name                 = "db-subnet"
  address_prefixes     = ["10.10.2.0/24"]  # 256 IPs
  service_endpoints    = ["Microsoft.Sql"]  # ← Portal에서 확인
}
```

#### 3. Connected Devices
```
Portal: VNet → Settings → Connected devices

확인:
- Application Gateway instances
- VMSS instances (2~5개)
- MySQL Server
- NAT Gateway
```

---

## Network Security Groups 확인

### appgw-nsg (Tier 1: Presentation)

#### Portal 경로
```
Resource groups → dev-rg → appgw-nsg
```

#### Inbound Rules
```
Portal: NSG → Settings → Inbound security rules

확인:
┌──────────┬──────────────────┬──────┬──────────┬────────┬──────────┐
│ Priority │ Name             │ Port │ Protocol │ Source │ Action   │
├──────────┼──────────────────┼──────┼──────────┼────────┼──────────┤
│ 100      │ allow-http       │ 80   │ TCP      │ *      │ Allow    │
│ 110      │ allow-https      │ 443  │ TCP      │ *      │ Allow    │
│ 120      │ allow-appgw-mgmt │ 65200│ TCP      │ GW Mgr │ Allow    │
│          │                  │-65535│          │        │          │
└──────────┴──────────────────┴──────┴──────────┴────────┴──────────┘
```

**Terraform 코드 비교:**
```terraform
# modules/nsg/main.tf
resource "azurerm_network_security_rule" "appgw_http" {
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
}
```

### app-nsg (Tier 2: Application)

#### Inbound Rules
```
Portal: dev-rg → app-nsg → Inbound security rules

확인:
┌──────────┬───────────────────┬──────┬──────────┬────────────────┬──────────┐
│ Priority │ Name              │ Port │ Protocol │ Source         │ Action   │
├──────────┼───────────────────┼──────┼──────────┼────────────────┼──────────┤
│ 100      │ allow-from-appgw  │ 80   │ TCP      │ 10.10.0.0/27   │ Allow    │
└──────────┴───────────────────┴──────┴──────────┴────────────────┴──────────┘
```

**의미:**
- App Subnet은 Application Gateway Subnet(10.10.0.0/27)에서만 접근 가능
- 인터넷에서 직접 접근 불가 (보안 강화)

#### Outbound Rules
```
Portal: app-nsg → Outbound security rules

확인:
┌──────────┬────────────────────────┬──────┬──────────┬──────────────┬──────────┐
│ Priority │ Name                   │ Port │ Protocol │ Destination  │ Action   │
├──────────┼────────────────────────┼──────┼──────────┼──────────────┼──────────┤
│ 100      │ allow-to-db            │ 3306 │ TCP      │ 10.10.2.0/24 │ Allow    │
│ 110      │ allow-to-internet-nat  │ *    │ *        │ Internet     │ Allow    │
└──────────┴────────────────────────┴──────┴──────────┴──────────────┴──────────┘
```

**의미:**
- DB Subnet(10.10.2.0/24)의 MySQL(3306)로만 아웃바운드
- 인터넷 아웃바운드는 NAT Gateway를 통해서만 (Public IP 공유)

### db-nsg (Tier 3: Data)

#### Inbound Rules
```
Portal: dev-rg → db-nsg → Inbound security rules

확인:
┌──────────┬────────────────────────┬──────┬──────────┬────────────────┬──────────┐
│ Priority │ Name                   │ Port │ Protocol │ Source         │ Action   │
├──────────┼────────────────────────┼──────┼──────────┼────────────────┼──────────┤
│ 100      │ allow-mysql-from-app   │ 3306 │ TCP      │ 10.10.1.0/24   │ Allow    │
└──────────┴────────────────────────┴──────┴──────────┴────────────────┴──────────┘
```

**의미:**
- DB는 App Subnet(10.10.1.0/24)에서만 접근 가능
- 인터넷에서 직접 접근 불가 (완전 프라이빗)

#### Outbound Rules
```
Portal: db-nsg → Outbound security rules

확인:
┌──────────┬─────────────────────┬──────┬──────────┬──────────────┬──────────┐
│ Priority │ Name                │ Port │ Protocol │ Destination  │ Action   │
├──────────┼─────────────────────┼──────┼──────────┼──────────────┼──────────┤
│ 4096     │ deny-internet-out   │ *    │ *        │ Internet     │ Deny     │
└──────────┴─────────────────────┴──────┴──────────┴──────────────┴──────────┘
```

**의미:**
- 데이터베이스는 외부로 나가는 연결 없음 (보안 강화)

---

## NAT Gateway 확인

### Portal 경로
```
Resource groups → dev-rg → dev-vnet-nat-gw
```

### Terraform 코드와 비교
```terraform
# modules/nat_gateway/main.tf
resource "azurerm_nat_gateway" "this" {
  name                    = "dev-vnet-nat-gw"
  location                = "Korea Central"
  sku_name                = "Standard"
  idle_timeout_in_minutes = 4
}
```

### Portal에서 확인할 항목

#### 1. Overview
```
확인:
- Status: Succeeded
- Public IP addresses: nat-gateway-pip (1개)
- Associated subnets: app-subnet
```

#### 2. Outbound IP
```
Portal: NAT Gateway → Settings → Outbound IP

확인:
- Public IP: <NAT Gateway IP 주소>
- 이 IP로 VMSS의 모든 인스턴스가 인터넷에 나감
```

**테스트:**
```bash
# VMSS 인스턴스에서 실행 (Azure Portal Serial Console)
curl ifconfig.me
# 출력: <NAT Gateway IP> (모든 인스턴스가 동일한 IP)
```

#### 3. Subnets
```
Portal: NAT Gateway → Settings → Subnets

확인:
- Connected subnet: app-subnet
```

**Terraform 코드 비교:**
```terraform
# modules/nat_gateway/main.tf
resource "azurerm_subnet_nat_gateway_association" "app" {
  subnet_id      = var.app_subnet_id  # app-subnet
  nat_gateway_id = azurerm_nat_gateway.this.id
}
```

---

## Application Gateway 확인

### Portal 경로
```
Resource groups → dev-rg → dev-appgw
```

### Terraform 코드와 비교
```terraform
# modules/appgw/main.tf
resource "azurerm_application_gateway" "this" {
  name                = "dev-appgw"
  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }
}
```

### Portal에서 확인할 항목

#### 1. Frontend
```
Portal: App Gateway → Settings → Frontend IP configurations

확인:
- Name: appgw-frontend-ip
- Type: Public
- Public IP: appgw-public-ip
- IP Address: <Public IP 주소>
```

**접속 테스트:**
```bash
PUBLIC_IP=$(terraform output -raw appgw_public_ip)
curl -k https://${PUBLIC_IP}
```

#### 2. Backend Pools
```
Portal: App Gateway → Settings → Backend pools

확인:
- Name: appgw-backend-pool
- Backend targets: VMSS instances (2~5개)
- IP addresses: 10.10.1.4, 10.10.1.5, ...
```

**Terraform에서 VMSS 연결 확인:**
```terraform
# modules/vmss/main.tf
network_interface {
  ip_configuration {
    application_gateway_backend_address_pool_ids = var.backend_pool_ids
  }
}
```

#### 3. HTTP Settings
```
Portal: App Gateway → Settings → Backend settings

확인:
- Name: appgw-backend-http-settings
- Protocol: HTTP
- Port: 80
- Cookie affinity: Disabled
- Request timeout: 60 seconds
- Health probe: appgw-health-probe
```

#### 4. Health Probes
```
Portal: App Gateway → Monitoring → Backend health

확인:
- Health probe: appgw-health-probe
- Status: Healthy (모든 인스턴스)
- Response code: 200
```

**만약 Unhealthy라면:**
- VMSS 인스턴스의 Nginx 상태 확인
- NSG 규칙 확인
- Health Probe 경로 확인 (/)

#### 5. Listeners
```
Portal: App Gateway → Settings → Listeners

확인:
┌────────────────┬──────────┬──────┬──────────┬─────────────────┐
│ Name           │ Type     │ Port │ Protocol │ SSL Certificate │
├────────────────┼──────────┼──────┼──────────┼─────────────────┤
│ http-listener  │ Basic    │ 80   │ HTTP     │ -               │
│ https-listener │ Basic    │ 443  │ HTTPS    │ appgw-ssl-cert  │
└────────────────┴──────────┴──────┴──────────┴─────────────────┘
```

#### 6. Rules
```
Portal: App Gateway → Settings → Rules

확인:
┌──────────────────────────┬──────────┬────────────────┬──────────────────┐
│ Name                     │ Priority │ Listener       │ Target           │
├──────────────────────────┼──────────┼────────────────┼──────────────────┤
│ http-to-https-redirect   │ 100      │ http-listener  │ Redirect (HTTPS) │
│ https-routing-rule       │ 200      │ https-listener │ Backend Pool     │
└──────────────────────────┴──────────┴────────────────┴──────────────────┘
```

**테스트:**
```bash
# HTTP → HTTPS 리다이렉션 확인
curl -I http://${PUBLIC_IP}
# 출력: HTTP/1.1 301 Moved Permanently
#       Location: https://<public-ip>/

# HTTPS 직접 접속
curl -k -I https://${PUBLIC_IP}
# 출력: HTTP/1.1 200 OK
```

---

## VMSS 확인

### Portal 경로
```
Resource groups → dev-rg → dev-vmss
```

### Terraform 코드와 비교
```terraform
# modules/vmss/main.tf
resource "azurerm_linux_virtual_machine_scale_set" "this" {
  name                = "dev-vmss"
  sku                 = "Standard_B1s"
  instances           = 2
}
```

### Portal에서 확인할 항목

#### 1. Instances
```
Portal: VMSS → Settings → Instances

확인:
- Current instances: 2 (초기 설정)
- Instance state: Running
- Private IPs: 10.10.1.4, 10.10.1.5, ...
```

#### 2. Scaling
```
Portal: VMSS → Settings → Scaling

확인:
- Scale mode: Autoscale
- Minimum instances: 2
- Maximum instances: 5
- Scale rules:
  - Scale out when CPU > 70%
  - Scale in when CPU < 30%
```

**Terraform 코드 비교:**
```terraform
# modules/vmss/main.tf
resource "azurerm_monitor_autoscale_setting" "this" {
  profile {
    capacity {
      default = 2
      minimum = 2
      maximum = 5
    }
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        operator           = "GreaterThan"
        threshold          = 70
      }
    }
  }
}
```

#### 3. Networking
```
Portal: VMSS → Settings → Networking

확인:
- Virtual network: dev-vnet
- Subnet: app-subnet (10.10.1.0/24)
- Load balancing: Application Gateway (dev-appgw)
- Network security group: app-nsg
```

#### 4. Health
```
Portal: VMSS → Monitoring → Metrics

확인할 메트릭:
- Percentage CPU
- Network In/Out
- Disk Read/Write

Auto Scaling 테스트:
1. CPU 부하 발생 (ab 도구 사용)
2. Metrics에서 CPU 70% 초과 확인
3. Instances 탭에서 인스턴스 증가 확인 (2 → 3 → 4 ...)
```

---

## MySQL Database 확인

### Portal 경로
```
Resource groups → dev-rg → dev-mysql-unique123
```

### Terraform 코드와 비교
```terraform
# modules/database/main.tf
resource "azurerm_mysql_flexible_server" "this" {
  name                   = "dev-mysql-unique123"
  sku_name               = "B_Standard_B1ms"
  delegated_subnet_id    = var.db_subnet_id
  private_dns_zone_id    = azurerm_private_dns_zone.mysql.id
}
```

### Portal에서 확인할 항목

#### 1. Networking
```
Portal: MySQL Server → Settings → Networking

확인:
- Connectivity method: Private access (VNet Integration)
- Virtual network: dev-vnet
- Delegated subnet: db-subnet
- Private DNS zone: privatelink.mysql.database.azure.com
```

**의미:**
- Public IP 없음 (인터넷에서 접근 불가)
- VNet 내부에서만 접근 가능
- NSG로 App Subnet에서만 접근 허용

#### 2. Databases
```
Portal: MySQL Server → Settings → Databases

확인:
- Database name: appdb
- Charset: utf8mb4
- Collation: utf8mb4_unicode_ci
```

#### 3. Compute + Storage
```
Portal: MySQL Server → Settings → Compute + storage

확인:
- Compute tier: Burstable (B_Standard_B1ms)
- Compute size: 1 vCore, 2GB RAM
- Storage: 20GB (auto-grow enabled)
- Backup retention: 7 days
```

#### 4. Server Parameters
```
Portal: MySQL Server → Settings → Server parameters

확인:
- require_secure_transport: ON (SSL 필수)
```

**Terraform 코드 비교:**
```terraform
# modules/database/main.tf
resource "azurerm_mysql_flexible_server_configuration" "require_secure_transport" {
  name  = "require_secure_transport"
  value = "ON"
}
```

---

## 모니터링 및 로그

### Application Gateway 모니터링

```
Portal: dev-appgw → Monitoring → Metrics

확인할 메트릭:
- Total Requests: 전체 요청 수
- Failed Requests: 실패한 요청 수
- Response Status: 응답 상태 코드 분포
- Throughput: 처리량 (bytes/sec)
- Backend Response Time: 백엔드 응답 시간
```

### VMSS 모니터링

```
Portal: dev-vmss → Monitoring → Metrics

확인할 메트릭:
- Percentage CPU: CPU 사용률 (Auto Scaling 기준)
- Network In/Out: 네트워크 트래픽
- Disk Operations: 디스크 I/O
```

### MySQL 모니터링

```
Portal: dev-mysql-unique123 → Monitoring → Metrics

확인할 메트릭:
- Active Connections: 활성 연결 수
- CPU percent: CPU 사용률
- Storage percent: 스토리지 사용률
- IO percent: I/O 사용률
```

---

## 다음 단계

- [HTTPS 설정 가이드](./03-https-setup-guide.md)
- [Application Gateway 가이드](./04-application-gateway-guide.md)
- [Troubleshooting 가이드](./05-troubleshooting-guide.md)
