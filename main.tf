# Configure the Azure Provider
provider "azurerm" {
    skip_provider_registration = true
    features {}
}

variable "prefix" {
  default = "moga2021"
}

variable "location" {
  default = "westeurope"
}

variable "adminuser" {
  default = "vmadmin"
}

variable "adminpass" {
}

variable "resource_group" {
  default     = "kusco-mohamedghaleb-tt"
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name = var.resource_group
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create a Public IP
resource "azurerm_public_ip" "azuretestimgpubip" {
  name                         = "azuretestimgpubip"
  location            = var.location
  resource_group_name = var.resource_group
  allocation_method            = "Static"
}

# Create a Network security Group
resource "azurerm_network_security_group" "azuretestimgnsg" {
  name                = "azuretestimgnsg"
  location            = var.location
  resource_group_name = var.resource_group

  security_rule {
    name                       = "Allow_rdp"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  location            = var.location
  resource_group_name = var.resource_group

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.azuretestimgpubip.id
  }
}

# Connect the security group to the nic
resource "azurerm_network_interface_security_group_association" "azuretestimgvmnicnsg" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.azuretestimgnsg.id
}

resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}-vm"
  location            = var.location
  resource_group_name = var.resource_group
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_DS3_v2"

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "winvmhostname"
    admin_username = var.adminuser
    admin_password = var.adminpass
  }
  os_profile_windows_config {
    enable_automatic_upgrades = true
  }
  tags = {
    environment = "kusco_vm_test"
  }
}
