provider "azurerm" {
  subscription_id = "${var.subscriptionId}"
  client_id       = "${var.clientId}"
  client_secret   = "${var.clientSecret}"
  tenant_id       = "${var.tenantId}"
}

terraform {
  backend "azurerm" {}
}

data "azurerm_key_vault_secret" "k8saztf" {
  name      = "${var.ssh-secret-name}"
  vault_uri = "https://${var.ssh-keyvault-name}.vault.azure.net/"
}

resource "azurerm_resource_group" "k8saztf" {
  name     = "x-rg-euw-k8saztf"
  location = "${var.azureRegion}"

  tags = {
    deployed-by = "terraform"
    environment = "${var.environment}"
  }
}

resource "azurerm_virtual_network" "k8saztf" {
  name                = "x-vn-euw-k8saztf-vnet-01"
  resource_group_name = "${azurerm_resource_group.k8saztf.name}"

  // cidrsubnet function?

  address_space = ["10.240.0.0/16"]
  location      = "${var.azureRegion}"
  tags = {
    deployed-by = "terraform"
    environment = "${var.environment}"
  }
}

resource "azurerm_network_security_group" "k8saztf" {
  name                = "x-nsg-euw-k8saztf"
  location            = "${var.azureRegion}"
  resource_group_name = "${azurerm_resource_group.k8saztf.name}"

  tags = {
    deployed-by = "terraform"
    environment = "${var.environment}"
  }
}

resource "azurerm_network_security_rule" "k8saztf-ssh-rule" {
  name                        = "x-nsg-euw-k8saztf-ssh-rule"
  resource_group_name         = "${azurerm_resource_group.k8saztf.name}"
  network_security_group_name = "${azurerm_network_security_group.k8saztf.name}"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "k8saztf-https-rule" {
  name                        = "x-nsg-euw-k8saztf-https-rule"
  resource_group_name         = "${azurerm_resource_group.k8saztf.name}"
  network_security_group_name = "${azurerm_network_security_group.k8saztf.name}"
  priority                    = 1020
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "6443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_subnet" "k8saztf" {
  name                      = "x-sn-euw-k8saztf-vnet-01-sn-01"
  address_prefix            = "10.240.0.0/24"
  virtual_network_name      = "${azurerm_virtual_network.k8saztf.name}"
  resource_group_name       = "${azurerm_resource_group.k8saztf.name}"
  network_security_group_id = "${azurerm_network_security_group.k8saztf.id}"
}

resource "azurerm_public_ip" "k8saztf" {
  name                         = "${var.environments["${var.environment}"]}-pip-${var.azureRegions["${var.azureRegion}"]}-${var.name}"
  location                     = "${var.azureRegion}"
  resource_group_name          = "${azurerm_resource_group.k8saztf.name}"
  public_ip_address_allocation = "static"

  tags = {
    deployed-by = "terraform"
    environment = "${var.environment}"
  }
}

resource "azurerm_public_ip" "k8saztf-ctrl-vm" {
  count = 3
  name                         = "x-pip-euw-k8sctrl-pip${count.index}"
  location                     = "${var.azureRegion}"
  resource_group_name          = "${azurerm_resource_group.k8saztf.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_network_interface" "k8saztf-ctrl-vm" {
  count = 3
  name                = "x-nic-euw-k8sctrl-nic${count.index}"
  location            = "${var.azureRegion}"
  resource_group_name = "${azurerm_resource_group.k8saztf.name}"

  ip_configuration = {
    name                          = "x-ip-euw-k8sctrl-ip${count.index}"
    subnet_id                     = "${azurerm_subnet.k8saztf.id}"
    public_ip_address_id          = "${element(azurerm_public_ip.k8saztf-ctrl-vm.*.id, count.index)}"
    private_ip_address_allocation = "static"
    private_ip_address = "10.240.0.1${count.index}"
  }
}

resource "azurerm_virtual_machine" "k8saztf-ctrl-vm" {
  count = 3
  name                             = "x-vl-euw-k8sctrl-${count.index}"
  location                         = "${var.azureRegion}"
  resource_group_name              = "${azurerm_resource_group.k8saztf.name}"
  vm_size                          = "Standard_D1_v2"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true
  network_interface_ids            = ["${element(azurerm_network_interface.k8saztf-ctrl-vm.*.id, count.index)}"]

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "x-os-euw-k8sctrl-${count.index}-disk0"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "x-vl-euw-k8sctrl-${count.index}"
    admin_username = "guvnor"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      key_data = "${data.azurerm_key_vault_secret.k8saztf.value}"
      path     = "/home/guvnor/.ssh/authorized_keys"
    }
  }
}
resource "azurerm_public_ip" "k8saztf-node-vm" {
  count = 3
  name                         = "x-pip-euw-k8snode-pip${count.index}"
  location                     = "${var.azureRegion}"
  resource_group_name          = "${azurerm_resource_group.k8saztf.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_network_interface" "k8saztf-node-vm" {
  count = 3
  name                = "x-nic-euw-k8snode-nic${count.index}"
  location            = "${var.azureRegion}"
  resource_group_name = "${azurerm_resource_group.k8saztf.name}"

  ip_configuration = {
    name                          = "x-ip-euw-k8snode-ip${count.index}"
    subnet_id                     = "${azurerm_subnet.k8saztf.id}"
    public_ip_address_id          = "${element(azurerm_public_ip.k8saztf-node-vm.*.id, count.index)}"
    private_ip_address_allocation = "static"
    private_ip_address = "10.240.0.2${count.index}"
  }
}

resource "azurerm_virtual_machine" "k8saztf-node-vm" {
  count = 3
  name                             = "x-vl-euw-k8snode-${count.index}"
  location                         = "${var.azureRegion}"
  resource_group_name              = "${azurerm_resource_group.k8saztf.name}"
  vm_size                          = "Standard_D1_v2"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true
  network_interface_ids            = ["${element(azurerm_network_interface.k8saztf-node-vm.*.id, count.index)}"]

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "x-os-euw-k8snode-${count.index}-disk0"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "x-vl-euw-k8snode-${count.index}"
    admin_username = "guvnor"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      key_data = "${data.azurerm_key_vault_secret.k8saztf.value}"
      path     = "/home/guvnor/.ssh/authorized_keys"
    }
  }
}

