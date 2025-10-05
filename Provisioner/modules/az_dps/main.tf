data "azurerm_iothub" "iot_hub" {
  name                = var.iot_hub_name
  resource_group_name = var.resource_group
}

# To read from azure 
# data "azurerm_iothub_shared_access_policy" "iot_hub_owner" {
#   name                = var.dps_name
#   resource_group_name = var.resource_group
#   iothub_name         = var.iot_hub_name
# }

resource "azurerm_iothub_dps" "az_dps" {
  name                = var.dps_name
  resource_group_name = var.resource_group
  location            = var.location

  sku {
    name     = "S1"
    capacity = 1
  }

  linked_hub {
    location = var.location
    connection_string = var.iot_hub_owner_connection_string
  }

  tags = {
    environment = var.environment_tag
    client_tag  = var.client_tag
  }
}


resource "azurerm_iothub_dps_shared_access_policy" "dps_policy" {
  name                = "provisioningserviceowner"
  resource_group_name = var.resource_group
  iothub_dps_name     = azurerm_iothub_dps.az_dps.name
  service_config      = true
  enrollment_read     = true
  enrollment_write    = true
}