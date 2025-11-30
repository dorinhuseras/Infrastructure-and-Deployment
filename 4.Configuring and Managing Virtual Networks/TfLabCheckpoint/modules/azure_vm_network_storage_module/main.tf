# Terraform module: Azure VM + VNet + Subnets + Storage + Private Endpoint + ASGs + NSG

############################################
# RESOURCE GROUP
############################################
resource "azurerm_resource_group" "rg" {
  name     = "${var.name_prefix}-rg"
  location = var.location
}

############################################
# VNET + SUBNETS
############################################
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.name_prefix}-vnet"
  address_space       = ["10.${var.vnet_octet}.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "frontend" {
  name                 = "${var.name_prefix}-frontend-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.${var.vnet_octet}.1.0/24"]
}

resource "azurerm_subnet" "backend" {
  name                 = "${var.name_prefix}-backend-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.${var.vnet_octet}.2.0/24"]
}

resource "azurerm_subnet" "data" {
  name                 = "${var.name_prefix}-data-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.${var.vnet_octet}.3.0/24"]
  private_endpoint_network_policies = "Enabled"
}

############################################
# APPLICATION SECURITY GROUPS (ASGs)
############################################
resource "azurerm_application_security_group" "vm_asg" {
  name                = "${var.name_prefix}-vm-asg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_application_security_group" "data_asg" {
  name                = "${var.name_prefix}-data-asg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

############################################
# NETWORK SECURITY GROUPS - ONE PER SUBNET
############################################
resource "azurerm_network_security_group" "frontend_nsg" {
  name                = "${var.name_prefix}-frontend-subnet-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet_network_security_group_association" "frontend_nsg_assoc" {
  subnet_id                 = azurerm_subnet.frontend.id
  network_security_group_id = azurerm_network_security_group.frontend_nsg.id
}

resource "azurerm_network_security_group" "backend_nsg" {
  name                = "${var.name_prefix}-backend-subnet-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet_network_security_group_association" "backend_nsg_assoc" {
  subnet_id                 = azurerm_subnet.backend.id
  network_security_group_id = azurerm_network_security_group.backend_nsg.id
}

resource "azurerm_network_security_group" "data_nsg" {
  name                = "${var.name_prefix}-data-subnet-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet_network_security_group_association" "data_nsg_assoc" {
  subnet_id                 = azurerm_subnet.data.id
  network_security_group_id = azurerm_network_security_group.data_nsg.id
}

############################################
# NETWORK SECURITY RULES - BACKEND NSG
############################################
resource "azurerm_network_security_rule" "vm_to_data" {
  name                        = "VM-to-Data"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_application_security_group_ids      = [azurerm_application_security_group.vm_asg.id]
  destination_application_security_group_ids = [azurerm_application_security_group.data_asg.id]
  destination_port_range      = "*"
  source_port_range           = "*"
  network_security_group_name = azurerm_network_security_group.data_nsg.name
  resource_group_name         = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "allow_http_from_internet" {
  name                        = "Allow-HTTP-Internet"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.backend_nsg.name
  resource_group_name         = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "allow_rdp_from_internet" {
  name                        = "Allow-RDP-Internet"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.backend_nsg.name
  resource_group_name         = azurerm_resource_group.rg.name
}

# Default deny-all inbound rule for frontend NSG (restrictive, explicit-allow)
resource "azurerm_network_security_rule" "frontend_deny_all_inbound" {
  name                        = "Deny-All-Inbound"
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.frontend_nsg.name
  resource_group_name         = azurerm_resource_group.rg.name
}

# Default deny-all inbound rule for backend NSG (restrictive, explicit-allow)
resource "azurerm_network_security_rule" "backend_deny_all_inbound" {
  name                        = "Deny-All-Inbound"
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.backend_nsg.name
  resource_group_name         = azurerm_resource_group.rg.name
}

# Default deny-all inbound rule for data NSG (restrictive, explicit-allow)
resource "azurerm_network_security_rule" "data_deny_all_inbound" {
  name                        = "Deny-All-Inbound"
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.data_nsg.name
  resource_group_name         = azurerm_resource_group.rg.name
}

############################################
# STORAGE ACCOUNT
############################################
resource "azurerm_storage_account" "sa" {
  name                     = "${replace(var.name_prefix, "-", "")}${random_integer.sa_suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  public_network_access_enabled = false
}

resource "random_integer" "sa_suffix" {
  min = 10000
  max = 99999
}

############################################
# PRIVATE ENDPOINT FOR STORAGE ACCOUNT
############################################
resource "azurerm_private_endpoint" "sa_pe" {
  name                = "${var.name_prefix}-storage-pe"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.data.id

  private_service_connection {
    name                           = "sa-priv-conn"
    private_connection_resource_id = azurerm_storage_account.sa.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }
}

resource "azurerm_private_endpoint_application_security_group_association" "pe_asg" {
  private_endpoint_id          = azurerm_private_endpoint.sa_pe.id
  application_security_group_id = azurerm_application_security_group.data_asg.id
}

############################################
# PRIVATE DNS ZONE + VNET LINK
############################################
resource "azurerm_private_dns_zone" "sa_dns" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "sa_dns_link" {
  name                  = "${var.name_prefix}-sa-dns-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.sa_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_private_dns_a_record" "sa_a_record" {
  name                = azurerm_storage_account.sa.name
  zone_name           = azurerm_private_dns_zone.sa_dns.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 300

  records = [azurerm_private_endpoint.sa_pe.private_service_connection[0].private_ip_address]
}

############################################
# PUBLIC IP FOR VM
############################################
resource "azurerm_public_ip" "vm_pip" {
  name                = "${var.name_prefix}-vm-public-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

############################################
# NETWORK INTERFACE FOR VM
############################################
resource "azurerm_network_interface" "vm_nic" {
  name                = "${var.name_prefix}-vm-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.backend.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_pip.id
  }
}

resource "azurerm_network_interface_application_security_group_association" "vm_nic_asg" {
  network_interface_id          = azurerm_network_interface.vm_nic.id
  application_security_group_id = azurerm_application_security_group.vm_asg.id
}


############################################
# VIRTUAL MACHINE
############################################
resource "azurerm_windows_virtual_machine" "vm" {
  name                = "${var.name_prefix}-vm"
  computer_name       = substr("${var.name_prefix}-vm", 0, 15)
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [azurerm_network_interface.vm_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-11"
    sku       = "win11-25h2-pro"
    version   = "latest"
  }
}