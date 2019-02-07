locals {
    spoke1-location = "CentralUS"
    spoke1-resource-group = "spoke1-vnet-rg"
    prefix = "spoke1"
}

resource "azurerm_resource_group"  "spoke1-vnet-rg" {
    name = "${local.spoke1-resource-group}"
    location = "${local.spoke1-location}"
}


resource "azurerm_virtual_network" "spoke1-vnet" {
  name                = "spoke1-vnet"
  location            = "${azurerm_resource_group.spoke1-vnet-rg.location}"
  resource_group_name = "${azurerm_resource_group.spoke1-vnet.name}"
  address_space       = ["10.1.0.0/16"]
  
  tags {
    environment = "${local.prefix}"
  }
}

 resource "azurerm_subnet" "spoke1-mgmt" {
  name                 = "mgmt"
  resource_group_name = "${azurerm_resource_group.spoke1-vnet-rg.name}"
  virtual_network_name = "${azurerm_virtual_network.spoke1-vnet.name}"
  address_prefix       = "10.0.0.64/27"
}

 resource "azurerm_subnet" "spoke1-workload" {
  name                 = "workload"
  resource_group_name = "${azurerm_resource_group.spoke1-vnet-rg.name}"
  virtual_network_name = "${azurerm_virtual_network.spoke1-vnet.name}"
  address_prefix       = "10.1.1.0/24"
}


resource "azurerm_virtual_network_peering" "spoke1-hub-peer" {
  name                         = "spoke1-hub-peer"
  resource_group_name          = "${azurerm_resource_group.spoke1-vnet-rg.name}"
  virtual_network_name         = "${azurerm_virtual_network.spoke1-vnet.name}"
  remote_virtual_network_id    = "${azurerm_virtual_network.hub-vnet.id}"
  allow_virtual_network_access = true
  allow_forwarded_traffic = true
  allow_gateway_transit = false
  use_remote_gateways = true

}

resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  location            = "${azurerm_resource_group.spoke1-vnet-rg.location}"
  resource_group_name = "${azurerm_resource_group.spoke1-vnet-rg.name}"
  enable_ip_forwarding = true
  

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = "${azurerm_subnet.spoke1-mgmt.id}"
    private_ip_address_allocation = "Static"
    
  }
}

resource "azurerm_virtual_machine" "spoke1-vm" {
  name                  = "${var.prefix}-vm"
  location              = "${azurerm_resource_group.main.location}"
  resource_group_name   = "${azurerm_resource_group.main.name}"
  network_interface_ids = ["${azurerm_network_interface.main.id}"]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "${local.prefix}-vm"
    admin_username = "${var.username}"
    admin_password = "${var.password}"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags {
    environment = "${local.prefix}"
  }
}
