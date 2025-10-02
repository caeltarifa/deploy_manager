resource "azurerm_iothub" "iothub" {
  name                = var.iothub_name
  resource_group_name = var.resource_group_name
  location            = var.location

  sku {
    name     = "S1"
    capacity = 1
  }

  tags = {
    "Environment" = "Testing"
  }
}

output "iothub_id" {
  value = azurerm_iothub.iothub.id
}