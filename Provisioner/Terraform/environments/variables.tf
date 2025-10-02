variable "iothub_name" {
  description = "The name of the IoT Hub."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group."
  type        = string
}

variable "location" {
  description = "The Azure region."
  type        = string
}

variable "iot_edge_devices" {
  description = "A map of IoT Edge devices and their custom modules to import."
  type        = map(any)
}