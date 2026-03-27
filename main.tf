terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.26.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7.1"
    }
  }
}

data "azurerm_subscription" "current" {}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.application_name
  location = var.location
}
