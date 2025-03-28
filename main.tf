# Include the additional policies and override archetypes
provider "alz" {
  library_references = [
    {
      path = "platform/alz",
      # should i keep this string empty, or do versioning?
      ref  = ""
    },
    {
      custom_url = "${path.root}/lib"
    }
  ]
}

# This allows us to get the tenant id
data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "update_manager" {
  location = local.location
  name     = local.update_manager_rg_name
}

resource "azurerm_maintenance_configuration" "this" {
  location                 = azurerm_resource_group.update_manager.location
  name                     = local.maintenance_configuration_name
  resource_group_name      = azurerm_resource_group.update_manager.name
  scope                    = "InGuestPatch"
  in_guest_user_patch_mode = "User"

  install_patches {
    reboot = "IfRequired"

    windows {
      classifications_to_include = ["Critical", "Security", "Definition"]
    }
  }
  window {
    start_date_time = "2024-01-03 00:00"
    time_zone       = "GMT Standard Time"
    duration        = "03:55"
    recur_every     = "Week"
  }
}

# The provider shouldn't have any unknown values passed in, or it will mark
# all resources as needing replacement.
locals {
  location                              = "swedencentral"
  maintenance_configuration_name        = "ring1"
  maintenance_configuration_resource_id = provider::azapi::resource_group_resource_id(data.azurerm_client_config.current.subscription_id, local.update_manager_rg_name, "Microsoft.Maintenance/maintenanceConfigurations", [local.maintenance_configuration_name])
  update_manager_rg_name                = "rg-update-manager"
  architecture_name                     = "custom"
}


  # policy_assignments_to_modify = {
  #   myroot = {
  #     policy_assignments = {
    # enforcement_mode = "DoNotEnforce"
  #       Update-Ring1 = {
  #         parameters = {
  #           maintenanceConfigurationResourceId = jsonencode({ value = local.maintenance_configuration_resource_id })
  #         }
  #       }

  #       Enable-DDoS-VNET = {
  #         enforcement_mode = "DoNotEnforce"
  #       }

  #       SQL = {
  #         enforcement_mode = "DoNotEnforce"
  #       }

  #     }
  #   }
  # }


module "avm-ptn-alz" {
  source  = "Azure/avm-ptn-alz/azurerm"
  version = "0.11.1"
  architecture_name  = local.architecture_name
  parent_resource_id = data.azurerm_client_config.current.tenant_id
  location           = local.location
}