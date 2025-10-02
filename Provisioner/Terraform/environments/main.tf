module "iot_hub" {
  source = "../../modules/iot-hub"
  
  # Pass variables from tfvars file
  iothub_name         = var.iothub_name
  resource_group_name = var.resource_group_name
  location            = var.location
}

# IoT Edge Host module manages all 15 devices.
# The `for_each` loop iterates over the map of devices defined in the `tfvars` file.
module "iot_edge_host" {
  source = "../../modules/iot-edge-host"
  
  for_each = var.iot_edge_devices
  
  # Pass variables from the `for_each` iterator to the module
  iothub_id           = module.iot_hub.iothub_id
  iotedge_device_name = each.key
  custom_modules      = each.value.custom_modules
}