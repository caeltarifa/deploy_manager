
output "name" {
  value = azurerm_iothub.prod_iothub.name
}

output "connection_string" {
  description = "Primary connection string for IoT Hub"
  value = azurerm_iothub_shared_access_policy.iothub_policy.primary_connection_string
  sensitive = true
}