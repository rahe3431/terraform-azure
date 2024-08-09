terraform {
    required_providers {
        azurerm = {
            source = "hashicorp/azurerm"
            version = "2.15.0"
        }
    }
}

provider "azurerm" {
    feature {}
}