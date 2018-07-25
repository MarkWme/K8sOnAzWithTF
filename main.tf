provider "azurerm" {
  subscription_id = "${var.subscriptionId}"
  client_id       = "${var.clientId}"
  client_secret   = "${var.clientSecret}"
  tenant_id       = "${var.tenantId}"
}

terraform {
  backend "azurerm" {}
}

resource "azurerm_resource_group" "k8saztf" {
  name     = "x-rg-euw-k8saztf"
  location = "${var.azureRegion}"
}
