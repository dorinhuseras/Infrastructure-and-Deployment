variable "name_prefix" { 
  type        = string
  description = "Prefix for all resource names"
}

variable "location" { type = string }

variable "vnet_octet" { type = number }

variable "vm_size"        { type = string }
variable "admin_username" { type = string }
variable "admin_password" { type = string }