# ============================================================================
# Development Environment: 3-Tier Architecture with HTTPS
# ============================================================================
# 아키텍처:
# - Tier 1: Application Gateway (HTTPS)
# - Tier 2: VMSS (애플리케이션 서버)
# - Tier 3: Azure Database for MySQL
# ============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# ============================================================================
# Local Variables
# ============================================================================
locals {
  environment = "dev"
  project     = "7-https-appgw"

  common_tags = {
    Environment = local.environment
    Project     = local.project
    ManagedBy   = "terraform"
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
  }
}

# ============================================================================
# Network Module: VNet 및 서브넷
# ============================================================================
module "network" {
  source = "../../modules/network"

  resource_group_name = var.resource_group_name
  location            = var.location
  vnet_name           = var.vnet_name
  vnet_cidr           = var.vnet_cidr
  appgw_subnet_cidr   = var.appgw_subnet_cidr
  app_subnet_cidr     = var.app_subnet_cidr
  db_subnet_cidr      = var.db_subnet_cidr

  tags = local.common_tags
}

# ============================================================================
# NSG Module: 네트워크 보안 그룹
# ============================================================================
module "nsg" {
  source = "../../modules/nsg"

  resource_group_name = module.network.resource_group_name
  location            = module.network.location

  appgw_subnet_id   = module.network.appgw_subnet_id
  appgw_subnet_cidr = var.appgw_subnet_cidr
  app_subnet_id     = module.network.app_subnet_id
  app_subnet_cidr   = var.app_subnet_cidr
  db_subnet_id      = module.network.db_subnet_id
  db_subnet_cidr    = var.db_subnet_cidr

  tags = local.common_tags
}

# ============================================================================
# NAT Gateway Module: App Subnet의 아웃바운드 인터넷 연결
# ============================================================================
module "nat_gateway" {
  source = "../../modules/nat_gateway"

  resource_group_name = module.network.resource_group_name
  location            = module.network.location
  app_subnet_id       = module.network.app_subnet_id

  nat_gateway_name     = "${var.vnet_name}-nat-gw"
  nat_gateway_pip_name = "${var.vnet_name}-nat-pip"

  tags = local.common_tags
}

# ============================================================================
# Application Gateway Module: HTTPS 로드 밸런서
# ============================================================================
module "appgw" {
  source = "../../modules/appgw"

  resource_group_name = module.network.resource_group_name
  location            = module.network.location
  appgw_name          = var.appgw_name
  public_ip_name      = "${var.appgw_name}-pip"
  domain_name_label   = var.domain_name_label
  appgw_subnet_id     = module.network.appgw_subnet_id

  # SKU 설정
  sku_name              = var.appgw_sku_name
  sku_tier              = var.appgw_sku_tier
  capacity              = var.appgw_capacity
  enable_autoscale      = var.appgw_enable_autoscale
  autoscale_min_capacity = var.appgw_autoscale_min_capacity
  autoscale_max_capacity = var.appgw_autoscale_max_capacity

  # SSL 인증서
  ssl_certificate_data     = var.ssl_certificate_data
  ssl_certificate_password = var.ssl_certificate_password
  ssl_policy_name          = var.ssl_policy_name

  # WAF 설정 (WAF_v2 SKU인 경우)
  waf_mode = var.waf_mode

  tags = local.common_tags
}

# ============================================================================
# VMSS Module: 애플리케이션 서버
# ============================================================================
module "vmss" {
  source = "../../modules/vmss"

  resource_group_name = module.network.resource_group_name
  location            = module.network.location
  vmss_name           = var.vmss_name
  subnet_id           = module.network.app_subnet_id
  backend_pool_ids    = [module.appgw.backend_pool_id]

  # VM 설정
  vm_sku         = var.vmss_vm_sku
  admin_username = var.vmss_admin_username
  admin_password = var.vmss_admin_password

  # Auto Scaling 설정
  initial_instance_count   = var.vmss_initial_instance_count
  min_instance_count       = var.vmss_min_instance_count
  max_instance_count       = var.vmss_max_instance_count
  scale_out_cpu_threshold  = var.vmss_scale_out_cpu_threshold
  scale_in_cpu_threshold   = var.vmss_scale_in_cpu_threshold

  tags = local.common_tags
}

# ============================================================================
# Database Module: Azure Database for MySQL
# ============================================================================
module "database" {
  source = "../../modules/database"

  resource_group_name = module.network.resource_group_name
  location            = module.network.location
  mysql_server_name   = var.mysql_server_name
  admin_username      = var.mysql_admin_username
  admin_password      = var.mysql_admin_password
  database_name       = var.mysql_database_name

  # SKU 및 스토리지
  sku_name         = var.mysql_sku_name
  storage_size_gb  = var.mysql_storage_size_gb

  # 백업 및 고가용성
  backup_retention_days        = var.mysql_backup_retention_days
  geo_redundant_backup_enabled = var.mysql_geo_redundant_backup_enabled
  enable_high_availability     = var.mysql_enable_high_availability

  # 네트워크
  vnet_id      = module.network.vnet_id
  db_subnet_id = module.network.db_subnet_id

  tags = local.common_tags
}
