resource "azurerm_network_interface" "main" {
  name                = "${azurerm_resource_group.main.name}-nic"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"

  network_security_group_id = "${azurerm_network_security_group.main.id}"

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = "${azurerm_subnet.internal.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id = "${azurerm_public_ip.main.id}"
  }
}

locals {
  username = "minecraftadmin"  
}

resource "azurerm_virtual_machine" "main" {
  name                  = "${azurerm_resource_group.main.name}-vm"
  location              = "${azurerm_resource_group.main.location}"
  resource_group_name   = "${azurerm_resource_group.main.name}"
  network_interface_ids = ["${azurerm_network_interface.main.id}"]
  vm_size               = "Standard_B2s"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = "${local.username}"
    admin_password = "${var.password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install unzip",
      "sudo apt-get install libcurl3 libcurl3-dev",
    ]

    connection {
        type     = "ssh"
        user     = "${local.username}"
        password = "${var.password}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir /minecraft",
      "cd /minecraft",
      "wget https://minecraft.azureedge.net/bin-linux/bedrock-server-1.6.1.0.zip",
      "unzip bedrock-server-1.6.1.0.zip",     
      "sudo cp /minecraft/libCrypto.so /usr/lib/libCrypto.so",
      "sudo ldconfig -v | grep libCrypto.so",
    ]

    connection {
        type     = "ssh"
        user     = "${local.username}"
        password = "${var.password}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT",      
      "sudo iptables -A INPUT -p udp --dport 19132 -j ACCEPT",
      "sudo iptables -A INPUT -p udp --dport 19133 -j ACCEPT",
    ]

    connection {
        type     = "ssh"
        user     = "${local.username}"
        password = "${var.password}"
    }
  }

  provisioner "file" {
    source = "../config/minecraft-server.service",
    destination = "/minecraft-server.service"

    connection {
        type     = "ssh"
        user     = "${local.username}"
        password = "${var.password}"
    }
  }

  provisioner "file" {
    source = "../config/whitelist.json",
    destination = "/minecraft/whitelist.json"

    connection {
        type     = "ssh"
        user     = "${local.username}"
        password = "${var.password}"
    }
  }

  provisioner "file" {
    source = "../config/ops.json",
    destination = "/minecraft/ops.json"

    connection {
        type     = "ssh"
        user     = "${local.username}"
        password = "${var.password}"
    }
  }

  provisioner "file" {
    source = "../config/server.properties",
    destination = "/minecraft/server.properties"

    connection {
        type     = "ssh"
        user     = "${local.username}"
        password = "${var.password}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cp /minecraft-server.service /etc/systemd/system/minecraft-server.service",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable minecraft-server",
      "sudo systemctl start minecraft-server",
    ]

    connection {
        type     = "ssh"
        user     = "${local.username}"
        password = "${var.password}"
    }
  }
}