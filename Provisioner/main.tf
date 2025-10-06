provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  resource_provider_registrations = "none"
}

module "iothub" {
  source          = "./modules/iothub"
  name            = var.iot_hub_name
  resource_group  = var.resource_group
  location        = var.location
  environment_tag = var.environment_tag
}

module "dps" {
  source          = "./modules/az_dps"
  dps_name        = var.dps_name
  resource_group  = var.resource_group
  location        = var.location
  iot_hub_name    = module.iothub.name
  environment_tag = var.environment_tag
  client_tag      = var.client_tag
  iot_hub_owner_connection_string = module.iothub.connection_string
}

module "enrollment" {
  source          = "./modules/enrollment"
  device_ids      = var.device_ids
  dps_name        = var.dps_name
  resource_group  = var.resource_group
  device_password = var.device_password
  client_tag      = var.client_tag
  environment_tag = var.environment_tag
  iot_hub_name    = var.iot_hub_name
  depends_on      = [module.dps,]
}
