output "iot_hub_name" {
  description = "Name of the provisioned IoT Hub"
  value       = module.iothub.name
}

output "dps_name" {
  description = "Name of the provisioned Device Provisioning Service"
  value       = module.dps.name
}

output "dps_scope_id" {
  description = "ID scope of DPS for device enrollment"
  value       = module.dps.id_scope
}

output "registered_devices" {
  description = "List of enrolled devices"
  value       = module.enrollment.enrolled_device_ids 
  sensitive   = true
}
