output "serverip" {
    value = "${azurerm_public_ip.main.ip_address}"
}

output "username" {
    value = "${local.username}"
}