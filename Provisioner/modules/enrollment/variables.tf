variable "device_ids" {
  type        = list(string)
  description = "List of device IDs to enroll"
}

variable "dps_name" {
  type        = string
  description = "DPS instance name"
}

variable "resource_group" {
  type        = string
  description = "Resource Group name"
}

variable "device_password" {
  type        = string
  description = "Base64 encoded symmetric key for devices"
  sensitive   = true
}

variable "client_tag" {
  description = "Client label for tagging devices"
  type        = string
}

variable "environment_tag" {
  description = "Environment label for tagging devices"
  type        = string
}

variable "iot_hub_name" {
  type        = string
  description = "IoT Hub name to link with DPS"
}

