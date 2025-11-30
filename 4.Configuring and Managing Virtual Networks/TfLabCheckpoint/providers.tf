terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "8d82146a-0138-4a26-884b-37480942ecd8"
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
