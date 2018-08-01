variable "subscriptionId" {
  type = "string"
}

variable "clientId" {
  type = "string"
}

variable "clientSecret" {
  type = "string"
}

variable "tenantId" {
  type = "string"
}

variable "name" {
  type    = "string"
  default = "k8saztf"
}

variable "ssh-keyvault-name" {
  type        = "string"
  description = "The name of the Key Vault instance where the SSH key for the Linux VM is stored. Just the name of the vault, not the URI"
}

variable "ssh-secret-name" {
  type = "string"
}

variable "azureRegions" {
  type = "map"

  default = {
    westeurope  = "euw"
    northeurope = "eun"
  }
}

variable "azureRegion" {
  type    = "string"
  default = "westeurope"
}

variable "environment" {
  type    = "string"
  default = "temp"
}

variable "environments" {
  type = "map"

  default = {
    development = "d"
    test        = "t"
    production  = "p"
    temp        = "x"
  }
}
