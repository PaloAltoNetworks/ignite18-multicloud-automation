/*
 * Copyright 2018 Palo Alto Networks
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


# Define the Azure resource group
resource "azurerm_resource_group" "myterraformgroup" {
        name = "${var.azure_resource_group}"
        location = "${var.azure_location}"
        tags {
            environment = "${var.azure_environment}"
        }
}

# Define the Azure virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "myVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "${azurerm_resource_group.myterraformgroup.location}"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"
}

# Define the Azure subnet
resource "azurerm_subnet" "myterraformsubnet" {
    name                 = "mySubnet"
    resource_group_name  = "${azurerm_resource_group.myterraformgroup.name}"
    virtual_network_name = "${azurerm_virtual_network.myterraformnetwork.name}"
    address_prefix       = "10.0.2.0/24"
}

# Define the Azure public IP address
resource "azurerm_public_ip" "myterraformpublicip" {
    name                         = "myPublicIP"
    location                     = "${azurerm_resource_group.myterraformgroup.location}"
    resource_group_name          = "${azurerm_resource_group.myterraformgroup.name}"
    public_ip_address_allocation = "dynamic"
}

# Define the Azure security group
resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "myNetworkSecurityGroup"
    location            = "${azurerm_resource_group.myterraformgroup.location}"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"

    security_rule {
        name                       = "SSH"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "Web"
        priority                   = 102
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

# Define the Azure virtual NIC
resource "azurerm_network_interface" "myterraformnic" {
    name                = "myNIC"
    location            = "${azurerm_resource_group.myterraformgroup.location}"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = "${azurerm_subnet.myterraformsubnet.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.myterraformpublicip.id}"
    }
}

# Generate a random 8-byte string to use in the storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${azurerm_resource_group.myterraformgroup.name}"
    }
    byte_length = 8
}

# Define the Azure storage account
resource "azurerm_storage_account" "mystorageaccount" {
    name                = "diag${random_id.randomId.hex}"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"
    location            = "${azurerm_resource_group.myterraformgroup.location}"
    account_replication_type = "LRS"
    account_tier = "Standard"
}

# Define the Azure virtual machine
resource "azurerm_virtual_machine" "panos" {
  name                  = "panos-azure"
  location              = "${var.azure_location}"
  resource_group_name   = "${azurerm_resource_group.myterraformgroup.name}"
  vm_size               = "Standard_D3_v2"

  depends_on = ["azurerm_network_interface.myterraformnic"]

  plan {
    name = "bundle2"
    publisher = "paloaltonetworks"
    product = "vmseries1"

  }

  storage_image_reference {
    publisher = "paloaltonetworks"
    offer     = "vmseries1"
    sku       = "bundle2"
    version   = "latest"
  }

  storage_os_disk {
    name          = "fw-osdisk"
    vhd_uri       = "${azurerm_storage_account.mystorageaccount.primary_blob_endpoint}vhds/osdisk-DB.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "panos-azure"
    admin_username = "${var.azure_firewall_user}"
    admin_password = "${var.azure_firewall_password}"
  }

  primary_network_interface_id = "${azurerm_network_interface.myterraformnic.id}"
  network_interface_ids = ["${azurerm_network_interface.myterraformnic.id}"]

  os_profile_linux_config {
    disable_password_authentication = false
  }
}
