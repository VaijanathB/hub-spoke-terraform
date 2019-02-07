resource "azurerm_virtual_network_peering" "hub-spoke1-peer" {
  name                         = "hub-spoke1-peer"
  resource_group_name          = "${azurerm_resource_group.hub-vnet-rg.name}"
  virtual_network_name         = "${azurerm_virtual_network.hub-vnet.name}"
  remote_virtual_network_id    = "${azurerm_virtual_network.spoke1-vnet.id}"
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "test2" {
  name                         = "hub-spoke2-peer"
  resource_group_name          = "${azurerm_resource_group.hub-vnet-rg.name}"
  virtual_network_name         = "${azurerm_virtual_network.hub-vnet.name}"
  remote_virtual_network_id    = "${azurerm_virtual_network.spoke2-vnet.id}"
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
}
