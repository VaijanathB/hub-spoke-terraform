locals {
    prefix = "hub-nva"    
    hub-nva-location = "CentralUS"
    hub-nva-resource-group = "hub-nva-rg"

}

resource "azurerm_resource_group" "hub-nva-rg" {
  name     = "${local.prefix}-rg"
  location = "${local.hub-nva-location}"
  tags {
    environment = "${local.prefix}"
  }
}

resource "azurerm_network_interface" "hub-nva-nic" {
  name                = "${local.prefix}-nic"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  enable_ip_forwarding = true
  

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = "${azurerm_subnet.hub-dmz.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.0.36"
  }

  tags {
    environment = "${local.prefix}"
  }
}

resource "azurerm_virtual_machine" "main" {
  name                  = "${local.prefix}-vm"
  location              = "${azurerm_resource_group.hub-nva-rg.location}"
  resource_group_name   = "${azurerm_resource_group.hub-nva-rg.name}"
  network_interface_ids = ["${azurerm_network_interface.hub-nva-nic.id}"]
  vm_size               = "${var.vmsize}"

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

resource "azurerm_virtual_machine_extension" "enable-routes" {
  name                 = "enable-iptables-routes"
  location             = "${azurerm_resource_group.test.location}"
  resource_group_name  = "${azurerm_resource_group.test.name}"
  virtual_machine_name = "${azurerm_virtual_machine.test.name}"
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "fileUris": [
         "https://raw.githubusercontent.com/mspnp/reference-architectures/master/scripts/linux/enable-ip-forwarding.sh"
         ],
        "commandToExecute": "bash enable-ip-forwarding.sh"
    }
SETTINGS

  tags {
    environment = "${local.prefix}"
  }
}

resource "azurerm_route_table" "hub-gateway-rt" {
  name                          = "hub-gateway-rt"
  location                      = "${azurerm_resource_group.hub-nva-rg.location}"
  resource_group_name           = "${azurerm_resource_group.hub-nva-rg.name}"
  disable_bgp_route_propagation = false

  route {
    name           = "toHub"
    address_prefix = "10.0.0.0/16"
    next_hop_type  = "vnetlocal"
  }

   route {
    name           = "toSpoke1"
    address_prefix = "10.1.0.0/16"
    next_hop_type  = "vnetlocal"
  }
  route {
    name           = "toSpoke2"
    address_prefix = "10.2.0.0/16"
    next_hop_type  = "vnetlocal"
  }

  tags {
    environment = "${local.prefix}"
  }
}

resource "azurerm_route_table" "spoke1-rt" {
  name                          = "spoke1-rt"
  location                      = "${azurerm_resource_group.hub-nva-rg.location}"
  resource_group_name           = "${azurerm_resource_group.hub-nva-rg.name}"
  disable_bgp_route_propagation = false

  route {
    name           = "toSpoke2"
    address_prefix = "10.2.0.0/16"
    next_hop_type  = "vnetlocal"
    next_hop_in_ip_address = "10.0.0.36"
  }
  route {
      name = "default"
      address_prefix = "0.0.0.0/0"
      next_hop_type = "vnetlocal"
  }
  tags {
    environment = "${local.prefix}"
  }
}

resource "azurerm_route_table" "spoke2-rt" {
  name                          = "spoke2-rt"
  location                      = "${azurerm_resource_group.hub-nva-rg.location}"
  resource_group_name           = "${azurerm_resource_group.hub-nva-rg.name}"
  disable_bgp_route_propagation = false

  route {
    name           = "toSpoke1"
    address_prefix = "10.1.0.0/16"
    next_hop_in_ip_address = "10.0.0.36"
    next_hop_type  = "vnetlocal"
  }
  route {
      name = "default"
      address_prefix = "0.0.0.0/0"
      next_hop_type = "vnetlocal"
  }
  tags {
    environment = "${local.prefix}"
  }
}