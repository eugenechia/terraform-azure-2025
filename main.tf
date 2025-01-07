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

resource "azurerm_subnet_network_security_group_association" "eugene-lab-sga" {
  subnet_id                 = azurerm_subnet.eugene-lab-subnet.id
  network_security_group_id = azurerm_network_security_group.eugene-lab-sg.id
}

resource "azurerm_public_ip" "eugene-lab-publicip" {
  name                = "acceptanceTestPublicIp1"
  resource_group_name = azurerm_resource_group.tf-rg.name
  location            = azurerm_resource_group.tf-rg.location
  allocation_method   = "Static"

  tags = {
    environment = "Development"
  }
}

resource "azurerm_network_interface" "eugene-lab-nic" {
  name                = "eugene-lab-nic"
  location            = azurerm_resource_group.tf-rg.location
  resource_group_name = azurerm_resource_group.tf-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.eugene-lab-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.eugene-lab-publicip.id
  }

  tags = {
    environment = "dev"
  }
}

resource "azurerm_linux_virtual_machine" "eugene-lab-vm" {
  name                  = "eugene-vm"
  resource_group_name   = azurerm_resource_group.tf-rg.name
  location              = azurerm_resource_group.tf-rg.location
  size                  = "Standard_B1s"
  admin_username        = "eugenechia"
  network_interface_ids = [azurerm_network_interface.eugene-lab-nic.id]

  custom_data = filebase64("customdata.tpl")

  admin_ssh_key {
    username   = "eugenechia"
    public_key = file("~/.ssh/eugene-lab-azurekey.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  provisioner "local-exec" {
    command = templatefile("${var.host_os}-ssh-config.tpl", {
      hostname     = self.public_ip_address,
      user         = "eugenechia"
      identityfile = "~/.ssh/eugene-lab-azurekey"
    })
    interpreter = ["bash", "-c"]
  }

  tags = {
    environment = "dev"
  }
}

data "azurerm_public_ip" "eugene-lab-data" {
  name                = azurerm_public_ip.eugene-lab-publicip.name
  resource_group_name = azurerm_resource_group.tf-rg.name
}