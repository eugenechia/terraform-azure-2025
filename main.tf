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

resource "azurerm_virtual_network" "eugene-lab-vnet" {
  name                = "eugene-lab-vnet"
  location            = azurerm_resource_group.tf-rg.location
  resource_group_name = azurerm_resource_group.tf-rg.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "Dev"
  }
}

resource "azurerm_subnet" "eugene-lab-subnet" {
  name                 = "eugene-lab-subnet"
  resource_group_name  = azurerm_resource_group.tf-rg.name
  virtual_network_name = azurerm_virtual_network.eugene-lab-vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "eugene-lab-sg" {
  name                = "acceptanceTestSecurityGroup1"
  location            = azurerm_resource_group.tf-rg.location
  resource_group_name = azurerm_resource_group.tf-rg.name

  tags = {
    environment = "Dev"
  }
}

resource "azurerm_network_security_rule" "eugene-lab-sg-security-rule" {
  name                        = "dev-rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.tf-rg.name
  network_security_group_name = azurerm_network_security_group.eugene-lab-sg.name
}