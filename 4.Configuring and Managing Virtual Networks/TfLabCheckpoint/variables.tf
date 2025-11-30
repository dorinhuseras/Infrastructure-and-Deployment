variable "name_prefix" { 
  type        = string
  description = "Prefix for all resource names"
}

variable "location" { type = string }

variable "vnet_octet" {
  type = number
  description = "The middle octet of the VNet (10.X.0.0/16)"
}

variable "vm_size"        { type = string }
variable "admin_username" { type = string }
variable "admin_password" { type = string }