resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-ml-thesis"
  location            = local.location
  resource_group_name = local.resource_group_name
  address_space       = ["10.10.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "snet-ml-thesis"
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.1.0/24"]
}
