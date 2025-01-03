terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.14.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "144d2fee-e2bb-44b2-99bd-ef042ddeaa43"
}


resource "azurerm_resource_group" "tf-rg" {
  name     = "tf-rg"
  location = "Southeast Asia"
  tags = {
    environment = "dev"
  }
}