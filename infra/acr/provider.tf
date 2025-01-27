provider "azurerm" {
  features {}
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.3.0"

  backend "azurerm" {
    resource_group_name  = "rg-terraform"
    storage_account_name = "saeustfbackend01"
    container_name       = "tfstate"
    key                  = "acr.tfstate"
  }
}
