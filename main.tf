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


resource "azurerm_resource_group" "tf-test-rg" {
  name     = "tf-test-rg"
  location = "Southeast Asia"
  tags = {
    environment = "dev"
  }
}

resource "azurerm_virtual_network" "tf-test-vnet" {
  name                = "tf-test-vnet"
  location            = azurerm_resource_group.tf-test-rg.location
  resource_group_name = azurerm_resource_group.tf-test-rg.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "Dev"
  }
}

resource "azurerm_subnet" "tf-test-subnet" {
  name                 = "tf-test-subnet"
  resource_group_name  = azurerm_resource_group.tf-test-rg.name
  virtual_network_name = azurerm_virtual_network.tf-test-vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "tf-test-sg" {
  name                = "acceptanceTestSecurityGroup1"
  location            = azurerm_resource_group.tf-test-rg.location
  resource_group_name = azurerm_resource_group.tf-test-rg.name

  tags = {
    environment = "Dev"
  }
}

resource "azurerm_network_security_rule" "tf-test-sg-security-rule" {
  name                        = "dev-rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.tf-test-rg.name
  network_security_group_name = azurerm_network_security_group.tf-test-sg.name
}

resource "azurerm_subnet_network_security_group_association" "tf-test-sga" {
  subnet_id                 = azurerm_subnet.tf-test-subnet.id
  network_security_group_id = azurerm_network_security_group.tf-test-sg.id
}

resource "azurerm_public_ip" "tf-test-publicip" {
  name                = "acceptanceTestPublicIp1"
  resource_group_name = azurerm_resource_group.tf-test-rg.name
  location            = azurerm_resource_group.tf-test-rg.location
  allocation_method   = "Static"

  tags = {
    environment = "Development"
  }
}

resource "azurerm_network_interface" "tf-test-nic" {
  name                = "tf-test-nic"
  location            = azurerm_resource_group.tf-test-rg.location
  resource_group_name = azurerm_resource_group.tf-test-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.tf-test-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.tf-test-publicip.id
  }

  tags = {
    environment = "dev"
  }
}

resource "azurerm_linux_virtual_machine" "tf-test-vm" {
  name                  = "tf-test-vm"
  resource_group_name   = azurerm_resource_group.tf-test-rg.name
  location              = azurerm_resource_group.tf-test-rg.location
  size                  = "Standard_B1s"
  admin_username        = "eugenechia"
  network_interface_ids = [azurerm_network_interface.tf-test-nic.id]

  custom_data = filebase64("customdata.tpl")

  admin_ssh_key {
    username   = "eugenechia"
    public_key = file("geneazurelab.pub")
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
      identityfile = "geneazurelab"
    })
    interpreter = ["bash", "-c"]
  }

  tags = {
    environment = "dev"
  }
}

data "azurerm_public_ip" "tf-test-data" {
  name                = azurerm_public_ip.tf-test-publicip.name
  resource_group_name = azurerm_resource_group.tf-test-rg.name
}