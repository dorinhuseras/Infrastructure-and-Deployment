output "vm_private_ip" {
  value = azurerm_network_interface.vm_nic.ip_configuration[0].private_ip_address
}

output "vm_public_ip" {
  value = azurerm_public_ip.vm_pip.ip_address
}

output "storage_account_name" {
  value = azurerm_storage_account.sa.name
}

output "private_endpoint_ip" {
  value = azurerm_private_endpoint.sa_pe.private_service_connection[0].private_ip_address
}
