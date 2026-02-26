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