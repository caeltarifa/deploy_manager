variable "name" {
  type        = string
  description = "IoT Hub name"
}

variable "resource_group" {
  type        = string
  description = "Resource Group name"
}

variable "location" {
  type        = string
  description = "Azure location"
}

variable "environment_tag" {
  type        = string
  description = "Environment label"
}
