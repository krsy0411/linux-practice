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
  features {}
}

module "network" {
  source = "../../modules/network"

  resource_group_name = "dev-rg"
  location            = "Korea Central"

  vnet_name        = "dev-vnet"
  vnet_cidr        = "10.10.0.0/16"
  web_subnet_cidr  = "10.10.1.0/24"
  db_subnet_cidr   = "10.10.2.0/24"
}

module "nsg" {
  source = "../../modules/nsg"

  resource_group_name = module.network.resource_group_name
  location            = "Korea Central"

  web_subnet_id  = module.network.web_subnet_id # newtork 모듈의 output을 nsg 모듈의 input으로 전달(모듈 간 의존성 연결)
  db_subnet_id   = module.network.db_subnet_id # newtork 모듈의 output을 nsg 모듈의 input으로 전달(모듈 간 의존성 연결)
  web_subnet_cidr = "10.10.1.0/24"
}

module "loadbalancer" {
  source = "../../modules/loadbalancer"

  resource_group_name = module.network.resource_group_name
  location            = "Korea Central"
  backend_subnet_id   = module.network.web_subnet_id
}

module "vmss" {
  source = "../../modules/vmss"

  resource_group_name = module.network.resource_group_name
  location            = "Korea Central"
  subnet_id           = module.network.web_subnet_id # VMSS → Web Subnet 안에 배치
  backend_pool_id     = module.loadbalancer.backend_pool_id # VMSS → Load Balancer Backend Pool에 자동 등록
}