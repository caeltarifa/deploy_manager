# To read from azure 
# data "azurerm_iothub_dps" "dps" {
#   name                = var.dps_name
#   resource_group_name = var.resource_group
# }

resource "null_resource" "enroll_device" {
  for_each = toset(var.device_ids)

  provisioner "local-exec" {
    command = <<EOT
      az iot dps enrollment create \
        --dps-name ${var.dps_name} \
        --resource-group ${var.resource_group} \
        --enrollment-id ${each.key} \
        --attestation-type symmetricKey \
        --primary-key ${var.device_password} \
        --secondary-key ${var.device_password} \
        --provisioning-status enabled \
        --initial-twin-properties '{"labels":{"environment":{var.environment_tag},"client":{var.client_tag}}}'
    EOT
  }
}