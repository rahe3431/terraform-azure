# this initial category is required for main.tf files.
terraform {
  required_providers {
    azurerm = {
      # establish provider location and version
      source  = "hashicorp/azurerm"
      version = "3.0.0"
    }
  }
}

# must include features even if it is empty
provider "azurerm" {
  features {}
}

# define resource group
resource "azurerm_resource_group" "mtc-rg" {
  name     = "mtc-resources"
  location = "East US"
  tags = {
    environment = "dev"
  }
}

# create a virtual network to put on the resource group
resource "azurerm_virtual_network" "mtc-vn" {
  name                = "mtc-network"
  resource_group_name = azurerm_resource_group.mtc-rg.name #use reference whenever possible instead of string. This ensures that dependent resources don't build first, and that any name changes are carried through in references.
  location            = azurerm_resource_group.mtc-rg.location
  address_space       = ["10.123.0.0/16"]

  tags = {
    environment = "dev"
  }
}

# create a subnet on the virtual network
resource "azurerm_subnet" "mtc-sn" {
  name                 = "mtc-subnet-1"
  resource_group_name  = azurerm_resource_group.mtc-rg.name
  virtual_network_name = azurerm_virtual_network.mtc-vn.name
  address_prefixes     = ["10.123.1.0/24"]
}

resource "azurerm_network_security_group" "mtc-sg" {
  name                = "mtc-security-group"
  location            = azurerm_resource_group.mtc-rg.location
  resource_group_name = azurerm_resource_group.mtc-rg.name
  tags = {
    environment = "dev"
  }
}

# this security rule gives developers access to the network
resource "azurerm_network_security_rule" "mtc-dev-rule" {
  name                        = "mtc-dev-rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.mtc-rg.name
  network_security_group_name = azurerm_network_security_group.mtc-sg.name
}

# have to add an association if I want the rule to apply to subnets
resource "azurerm_subnet_network_security_group_association" "mtc-ass" {
  subnet_id                 = azurerm_subnet.mtc-sn.id
  network_security_group_id = azurerm_network_security_group.mtc-sg.id
}

# set an ip for the virtual dev machine
resource "azurerm_public_ip" "mtc-ip" {
  name                = "mtc-ip"
  resource_group_name = azurerm_resource_group.mtc-rg.name
  location            = azurerm_resource_group.mtc-rg.location
  allocation_method   = "Dynamic"
  tags = {
    environment = "dev"
  }
}

# create an interface for the virtual network
resource "azurerm_network_interface" "mtc-nif" {
  name                = "mtc-nif"
  location            = azurerm_resource_group.mtc-rg.location
  resource_group_name = azurerm_resource_group.mtc-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.mtc-sn.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.mtc-ip.id
  }
  tags = {
    environment = "dev"
  }
}

# create the vm itself
resource "azurerm_linux_virtual_machine" "mtc-vm" {
  name                  = "mtc-vm"
  resource_group_name   = azurerm_resource_group.mtc-rg.name
  location              = azurerm_resource_group.mtc-rg.location
  size                  = "Standard_B1s"
  admin_username        = "adminuser"
  network_interface_ids = [azurerm_network_interface.mtc-nif.id]
  # create ssh key so you can ssh into vm
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  # not sure what this is for but if I don't have it terraform yells at me
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # what type of OS image
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  tags = {
    environment = "dev"
  }
}


