resource "azurerm_resource_group" "rg" {
  name     = "acr-rg"
  location = "westeurope"
}

resource "azurerm_container_registry" "registry" {
  name                = "talentacademyacr"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  admin_enabled       = true
}
