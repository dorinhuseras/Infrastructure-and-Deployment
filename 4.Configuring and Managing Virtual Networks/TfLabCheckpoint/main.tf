module "infra" {
  source = "./modules/azure_vm_network_storage_module"

  name_prefix = var.name_prefix
  location    = var.location
  vnet_octet = var.vnet_octet

  vm_size        = var.vm_size
  admin_username = var.admin_username
  admin_password = var.admin_password
}