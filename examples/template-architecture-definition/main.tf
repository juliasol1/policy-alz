# This allows us to get the tenant id
data "azapi_client_config" "current" {}

provider "alz" {
  library_references = [
    {
      path = "platform/alz"
      ref  = "2024.07.3"
    },
    {
      custom_url = "${path.root}/lib"
    }
  ]


}

module "alz_architecture" {
  source             = "../../"
  architecture_name  = "custom"
  parent_resource_id = data.azapi_client_config.current.tenant_id
  location           = "northeurope"
}

locals {
  location                              = "swedencentral"
}

module "alz" {
  source             = "../../"
  architecture_name  = "alz"
  parent_resource_id = data.azapi_client_config.current.tenant_id
  location           = local.location

  policy_assignments_to_modify = {
    mycomp = {
      policy_assignments = {
        # As we don't have a DDOS protection plan, we need to disable this policy
        # to prevent a modify action from failing.
        Enable-DDoS-VNET = {
          enforcement_mode = "DoNotEnforce"
        }
        Enable-AUM-CheckUpdates = {
          enforcement_mode = "DoNotEnforce"
        }

      }
    }
  }
}
