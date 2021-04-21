data "azurerm_subnet" "subnet" {
  name                 = azurerm_subnet.subnet.name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  resource_group_name  = azurerm_resource_group.resource_group.name
}

data "azurerm_resource_group" "resource_group" {
  name = azurerm_resource_group.resource_group.name
}

locals {
  os_info = var.os_info == null ? lookup(var.standard_os, var.os_name, var.standard_os["Ubuntu"]) : var.os_info
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.virtual_machine_name}-nic"
  location            = data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.subnet.id
    private_ip_address_version    = var.nic_private_ip_address_version
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "virtual_machine" {
  name                = var.virtual_machine_name
  resource_group_name = data.azurerm_resource_group.resource_group.name
  location            = data.azurerm_resource_group.resource_group.location
  size                = var.virtual_machine_size
  admin_username      = var.virtual_machine_admin_username
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  admin_ssh_key {
    username   = var.admin_ssh_key_username
    public_key = file(var.admin_ssh_key_public_key_file)
  }

  os_disk {
    caching              = var.os_disk_caching
    storage_account_type = var.os_disk_storage_account_type
  }

  source_image_reference {
    publisher = local.os_info.publisher
    offer     = local.os_info.offer
    sku       = local.os_info.sku
    version   = local.os_info.version
  }
}
