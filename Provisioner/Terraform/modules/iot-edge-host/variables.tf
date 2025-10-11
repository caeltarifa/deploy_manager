variable "iothub_id" {
  description = "The ID of the parent IoT Hub."
  type        = string
}

variable "iotedge_device_name" {
  description = "The name of the IoT Edge device to import."
  type        = string
}

variable "custom_modules" {
  description = "A list of custom module names for the IoT Edge device."
  type        = list(string)
  default     = []
}