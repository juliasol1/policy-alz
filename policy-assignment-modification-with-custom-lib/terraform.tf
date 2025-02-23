terraform {
  required_version = ">= 1.9, < 2.0"
  required_providers {
    alz = {
      source  = "azure/alz"
      version = "~> 0.16"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  tenant_id       = "60484d41-f4c4-4a62-a76f-b056885aedd0"
  subscription_id = "a8fd746f-85be-4734-a7b6-3e532a9bfa77"
}
