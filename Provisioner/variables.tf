variable "device_password" {
  type        = string
  description = "Base64 encoded symmetric key for IoT Edge devices."
  sensitive   = true
}

variable "iot_hub_name" {
  type        = string
  description = "Name of the Azure IoT Hub."
}

variable "dps_name" {
  type        = string
  description = "Name of the Azure Device Provisioning Service (DPS)."
}

variable "resource_group" {
  type        = string
  description = "Azure Resource Group name."
}

variable "location" {
  type        = string
  description = "Azure region location."
}

variable "environment_tag" {
  type        = string
  description = "Environment label for tagging resources."
}

variable "client_tag" {
  type        = string
  description = "Client label for tagging resources."
}

variable "device_ids" {
  type        = list(string)
  description = "List of device IDs to create and enroll."
}

variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID."
}