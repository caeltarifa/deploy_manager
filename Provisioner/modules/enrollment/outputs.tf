#output "registered_devices" {
#  value     = [for d in azurerm_iothub_dps_enrollment.devices : d.enrollment_id]
#  sensitive = true
#}

output "enrolled_device_ids" {
  value = var.device_ids
}