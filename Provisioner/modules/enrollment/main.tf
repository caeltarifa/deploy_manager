# To read from azure 
# data "azurerm_iothub_dps" "dps" {
#   name                = var.dps_name
#   resource_group_name = var.resource_group
# }

resource "null_resource" "enroll_device" {
  for_each = toset(var.device_ids)

  triggers = {
    device_id       = each.key
    device_key      = var.device_password
    environment_tag = var.environment_tag
    client_tag      = var.client_tag
  }

  provisioner "local-exec" {
    command = <<EOT
      if ! az iot hub device-identity show --device-id ${each.key} --hub-name ${var.iot_hub_name} > /dev/null 2>&1; then
        az iot hub device-identity create \
          --device-id ${each.key} \
          --hub-name ${var.iot_hub_name} \
          --edge-enabled true \
          --auth-method "shared_private_key" \
          --primary-key ${var.device_password} \
          --secondary-key ${var.device_password} \
          --auth-type key \
          --status enabled \
          --valid-days 250
      else
        echo "Device ${each.key} already exists in IoT Hub ${var.iot_hub_name}"
      fi
    EOT
  }
}

resource "null_resource" "update_device_twin" {
  for_each = toset(var.device_ids)

  depends_on = [
    null_resource.enroll_device
  ]

  provisioner "local-exec" {
    command = <<EOT
      az iot hub device-twin update \
        --device-id ${each.key} \
        --hub-name ${var.iot_hub_name} \
        --tags "{\"environment\": \"${var.environment_tag}\", \"client\": \"${var.client_tag}\"}"
    EOT
  }
}

