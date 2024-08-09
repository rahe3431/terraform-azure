terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.15.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "mtc-rg" {
  name     = "mtc-resources"
  location = "East US"
  tags {
    environment = "dev"
  }
}