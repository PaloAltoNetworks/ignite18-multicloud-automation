# Define the Azure resource group
resource "azurerm_resource_group" "myterraformgroup" {
        name = "${var.resourcegroup}"
        location = "${var.location}"
        tags {
            environment = "${var.environment}"
        }
}

# Define the Azure virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "myVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "${azurerm_resource_group.myterraformgroup.location}"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"

    tags {
        environment = "${var.environment}"
    }
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

    tags {
        environment = "${var.environment}"
    }
}

# Define the Azure security group
resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "myNetworkSecurityGroup"
    location            = "${azurerm_resource_group.myterraformgroup.location}"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags {
        environment = "${var.environment}"
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

    tags {
        environment = "${var.environment}"
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

    tags {
        environment = "${var.environment}"
    }
}

# Define the Azure virtual machine
resource "azurerm_virtual_machine" "myterraformvm" {
    name                  = "myVM"
    location              = "${azurerm_resource_group.myterraformgroup.location}"
    resource_group_name   = "${azurerm_resource_group.myterraformgroup.name}"
    network_interface_ids = ["${azurerm_network_interface.myterraformnic.id}"]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "myvm"
        admin_username = "azureuser"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/azureuser/.ssh/authorized_keys"
            key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCiydkY6VWsht8p2bTRGum+EGy34F8LqY9zTIa/aR4r8BafSB4/l83bLihN2PP09r6FTH491JP5oCuyoaoTXSjHWOJyTVoyArmGRM7d4m6jtXxI1tqrqXUdCBsF2ZUhiLVarIBRT69aaMcv8aYfsU7joaE49/zkyHl63Ywpjf2TKC13N0M+2Xgfzzg4dGYavZcIUdYtpPy5gbxDZyKJJ4Pw8aWs+gIv4zYGcl3P/jG4eZLRnyPVgoPA4Km/qkqylvbdOeuGtPYq1c9B8HJO3SuzQx6DOz6MglwXrzu8gfGxTeN/QRaH++qajGrobJOMq5gzAkahl3HY6IoisyC6jWCT5YmoLh86X26h+/mPGr3OljimIw3z6yGKwJRgIQNLedvz4PL/beW8hcORS26m8CLhfloGlgYqNkxbyKhTO8xdCU0x9W1KGQqKhMUr9jeqXY/93FqN4s+McjL+FS/frdcOxGGGsTvGN/SVAKoUKfbmCdMEyQ56nJLIRx5eO3tEodi8pavO2Zw17U/TpFm6Mflt0Um1U0qGaaq0zRe5+vyeNLj54DrNsC9onQIlAexIVhSOB5JaXI1LHiMMgqRFpp7iETPRlt6HRgOb2Ja7LbhWdq0fIraKneGwRnyAUOzDCl7Vh1lkvcGZaWRpczKfUakx4U9uVPUpGiixr7Fvy5185w=="
        }
    }

    boot_diagnostics {
        enabled     = "true"
        storage_uri = "${azurerm_storage_account.mystorageaccount.primary_blob_endpoint}"
    }

    tags {
        environment = "${var.environment}"
    }
}
