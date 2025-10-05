output "name" {
  value = azurerm_iothub_dps.az_dps.name
}

output "id_scope" {
  value = azurerm_iothub_dps.az_dps.id_scope
}

output "primary_key" {
  value     = azurerm_iothub_dps_shared_access_policy.dps_policy.primary_key
  sensitive = true
}
