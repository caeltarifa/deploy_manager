resource "azurerm_iothub_device_identity" "iotedge_device" {
  name                      = var.iotedge_device_name
  iothub_id                 = var.iothub_id
  device_id                 = var.iotedge_device_name
  edge_enabled              = true
  authentication_type       = "sas"
  symmetric_key_enabled     = true
  initial_twin_properties   = jsonencode({
    tags = {
      "Environment" = "Production"
      "Group" = "Edge-Group-1"
    }
  })
}

resource "azurerm_iothub_device_module_identity" "edge_hub_module" {
  name        = "$edgeHub"
  iothub_id   = var.iothub_id
  device_id   = azurerm_iothub_device_identity.iotedge_device.device_id
  module_id   = "$edgeHub"

  initial_twin_properties = jsonencode({
    routes = {
      "allMessages" = "FROM /messages/* INTO $upstream"
    },
    storeAndForwardConfiguration = {
      timeToLiveSecs = 7200
    }
  })
}

resource "azurerm_iothub_device_module_identity" "edge_agent_module" {
  name        = "$edgeAgent"
  iothub_id   = var.iothub_id
  device_id   = azurerm_iothub_device_identity.iotedge_device.device_id
  module_id   = "$edgeAgent"
}

# The `for_each` loop will create a resource for each custom module
resource "azurerm_iothub_device_module_identity" "custom_modules" {
  for_each = toset(var.custom_modules)
  name        = each.value
  iothub_id   = var.iothub_id
  device_id   = azurerm_iothub_device_identity.iotedge_device.device_id
  module_id   = each.value

  initial_twin_properties = jsonencode({
    properties.desired = {
      # Specific properties for each custom module here
      "SomeProperty" = "SomeValue"
    }
  })
}