resource "azurerm_iothub" "prod_iothub" {
  name                = var.name
  resource_group_name = var.resource_group
  location            = var.location
  sku {
    name     = "S1"
    capacity = 1
  }
  tags = {
    environment = var.environment_tag
  }
}

resource "azurerm_iothub_shared_access_policy" "iothub_policy" {
  name                = "iothub-owner-policy"
  resource_group_name = azurerm_iothub.prod_iothub.resource_group_name
  iothub_name         = azurerm_iothub.prod_iothub.name
  registry_read       = true
  registry_write      = true
  service_connect     = true
  device_connect      = true
}