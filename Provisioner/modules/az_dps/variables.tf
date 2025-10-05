variable "dps_name" {
  type        = string
  description = "DPS instance name"
}

variable "resource_group" {
  type        = string
  description = "Resource Group name"
}

variable "location" {
  type        = string
  description = "Azure location"
}

variable "iot_hub_name" {
  type        = string
  description = "Linked IoT Hub name"
}

variable "environment_tag" {
  type        = string
  description = "Environment label"
}

variable "client_tag" {
  type        = string
  description = "Client label"
}

variable "iot_hub_owner_connection_string" {
  type        = string
  description = "IoT Hub owner connection string"
}