variable "architecture_name" {
  type        = string
  description = <<DESCRIPTION
The name of the architecture to create. This needs to be of the `*.alz_architecture_definition.[json|yaml|yml]` files.
DESCRIPTION
  nullable    = false
}

variable "location" {
  type        = string
  description = <<DESCRIPTION
The default location for resources in this management group. Used for policy managed identities.
DESCRIPTION
  nullable    = false
}

variable "parent_resource_id" {
  type        = string
  description = <<DESCRIPTION
The resource name of the parent management group. Use the tenant id to create a child of the tenant root group.
The `azurerm_client_config`/`azapi_client_config` data sources are able to retrieve the tenant id.
Do not include the `/providers/Microsoft.Management/managementGroups/` prefix.
DESCRIPTION
  nullable    = false

  validation {
    condition     = !strcontains(var.parent_resource_id, "/")
    error_message = "The parent resource id must be the name of the parent management group and should not contain `/`."
  }
  validation {
    condition     = length(var.parent_resource_id) > 0
    error_message = "The parent resource id must not be an empty string."
  }
}

variable "dependencies" {
  type = object({
    policy_role_assignments = optional(any, null)
    policy_assignments      = optional(any, null)
  })
  default     = {}
  description = <<DESCRIPTION
Place dependent values into this variable to ensure that resources are created in the correct order.
Ensure that the values placed here are computed/known after apply, e.g. the resource ids.

This is necessary as the unknown values and `depends_on` are not supported by this module as we use the alz provider.
See the "Unknown Values & Depends On" section above for more information.

e.g.

```hcl
dependencies = {
  policy_role_assignments = [
    module.dependency_example1.output,
    module.dependency_example2.output,
  ]
}
```
DESCRIPTION
  nullable    = false
}

variable "override_policy_definition_parameter_assign_permissions_set" {
  type = set(object({
    definition_name = string
    parameter_name  = string
  }))
  default = [
    {
      "definition_name" = "04754ef9-9ae3-4477-bf17-86ef50026304",
      "parameter_name"  = "userWorkspaceResourceId"
    },
    {
      "definition_name" = "fbc14a67-53e4-4932-abcc-2049c6706009",
      "parameter_name"  = "privateDnsZoneId"
    }
  ]
  description = <<DESCRIPTION
This list of objects allows you to set the [`assignPermissions` metadata property](https://learn.microsoft.com/azure/governance/policy/concepts/definition-structure-parameters#parameter-properties) of the supplied definition and parameter names.
This allows you to correct policies that haven't been authored correctly and means that the provider can generate the correct policy role assignments.

The value is a list of objects with the following attributes:

- `definition_name` - (Required) The name of the policy definition, ***for built-in policies this us a UUID***.
- `parameter_name` - (Required) The name of the parameter to set the assignPermissions property for.

The default value has been populated with the Azure Landing Zones policies that are assigned by default, but do not have the correct parameter metadata.
DESCRIPTION
}

variable "override_policy_definition_parameter_assign_permissions_unset" {
  type = set(object({
    definition_name = string
    parameter_name  = string
  }))
  default     = null
  description = <<DESCRIPTION
This list of objects allows you to unset the [`assignPermissions` metadata property](https://learn.microsoft.com/azure/governance/policy/concepts/definition-structure-parameters#parameter-properties) of the supplied definition and parameter names.
This allows you to correct policies that haven't been authored correctly, or prevent permissions being assigned for policies that are disabled in a policy set. The provider can then generate the correct policy role assignments.

The value is a list of objects with the following attributes:

- `definition_name` - (Required) The name of the policy definition, ***for built-in policies this us a UUID***.
- `parameter_name` - (Required) The name of the parameter to unset the assignPermissions property for.
DESCRIPTION
}

variable "partner_id" {
  type        = string
  default     = null
  description = <<DESCRIPTION
A value to be included in the telemetry tag. Requires the `enable_telemetry` variable to be set to `true`. The must be in the following format:

`<PARTNER_ID_UUID>:<PARTNER_DATA_UUID>`

e.g.

`00000000-0000-0000-0000-000000000000:00000000-0000-0000-0000-000000000000`
DESCRIPTION

  validation {
    error_message = "The partner id must be in the format <PARTNER_ID_UUID>:<PARTNER_DATA_UUID>. All letters must be lowercase"
    condition     = var.partner_id == null ? true : can(regex("^[a-f\\d]{4}(?:[a-f\\d]{4}-){4}[a-f\\d]{12}:[a-f\\d]{4}(?:[a-f\\d]{4}-){4}[a-f\\d]{12}$", var.partner_id))
  }
}

variable "policy_assignments_to_modify" {
  type = map(object({
    policy_assignments = map(object({
      enforcement_mode = optional(string, null)
      identity         = optional(string, null)
      identity_ids     = optional(list(string), null)
      parameters       = optional(map(string), null)
      non_compliance_messages = optional(set(object({
        message                        = string
        policy_definition_reference_id = optional(string, null)
      })), null)
      resource_selectors = optional(list(object({
        name = string
        resource_selector_selectors = optional(list(object({
          kind   = string
          in     = optional(set(string), null)
          not_in = optional(set(string), null)
        })), [])
      })))
      overrides = optional(list(object({
        kind  = string
        value = string
        override_selectors = optional(list(object({
          kind   = string
          in     = optional(set(string), null)
          not_in = optional(set(string), null)
        })), [])
      })))
    }))
  }))
  default     = {}
  description = <<DESCRIPTION
A map of policy assignment objects to modify the ALZ architecture with.
You only need to specify the properties you want to change.

The key is the id of the management group. The value is an object with a single attribute, `policy_assignments`.
The `policy_assignments` value is a map of policy assignments to modify.
The key of this map is the assignment name, and the value is an object with optional attributes for modifying the policy assignments.

- `enforcement_mode` - (Optional) The enforcement mode of the policy assignment. Possible values are `Default` and `DoNotEnforce`.
- `identity` - (Optional) The identity of the policy assignment. Possible values are `SystemAssigned` and `UserAssigned`.
- `identity_ids` - (Optional) A set of ids of the user assigned identities to assign to the policy assignment.
- `non_compliance_message` - (Optional) A set of non compliance message objects to use for the policy assignment. Each object has the following properties:
  - `message` - (Required) The non compliance message.
  - `policy_definition_reference_id` - (Optional) The reference id of the policy definition to use for the non compliance message.
- `parameters` - (Optional) The parameters to use for the policy assignment. The map key is the parameter name and the value is an JSON object containing a single `Value` attribute with the values to apply. This to mitigate issues with the Terraform type system. E.g. `{ defaultName = jsonencode({Value = \"value\"}) }`.
- `resource_selectors` - (Optional) A list of resource selector objects to use for the policy assignment. Each object has the following properties:
  - `name` - (Required) The name of the resource selector.
  - `selectors` - (Optional) A list of selector objects to use for the resource selector. Each object has the following properties:
    - `kind` - (Required) The kind of the selector. Allowed values are: `resourceLocation`, `resourceType`, `resourceWithoutLocation`. `resourceWithoutLocation` cannot be used in the same resource selector as `resourceLocation`.
    - `in` - (Optional) A set of strings to include in the selector.
    - `not_in` - (Optional) A set of strings to exclude from the selector.
- `overrides` - (Optional) A list of override objects to use for the policy assignment. Each object has the following properties:
  - `kind` - (Required) The kind of the override.
  - `value` - (Required) The value of the override. Supported values are policy effects: <https://learn.microsoft.com/azure/governance/policy/concepts/effects>.
  - `selectors` - (Optional) A list of selector objects to use for the override. Each object has the following properties:
    - `kind` - (Required) The kind of the selector.
    - `in` - (Optional) A set of strings to include in the selector.
    - `not_in` - (Optional) A set of strings to exclude from the selector.
DESCRIPTION
}

variable "policy_default_values" {
  type        = map(string)
  default     = null
  description = <<DESCRIPTION
A map of default values to apply to policy assignments. The key is the default name as defined in the library, and the value is an JSON object containing a single `value` attribute with the values to apply. This to mitigate issues with the Terraform type system. E.g. `{ defaultName = jsonencode({ value = \"value\"}) }`
DESCRIPTION
}

variable "retries" {
  type = object({
    management_groups = optional(object({
      error_message_regex = optional(list(string), [
        "AuthorizationFailed", # Avoids a eventual consistency issue where a recently created management group is not yet available for a GET operation.
        "Permission to Microsoft.Management/managementGroups on resources of type 'Write' is required on the management group or its ancestors."
      ])
      interval_seconds     = optional(number, null)
      max_interval_seconds = optional(number, null)
      multiplier           = optional(number, null)
      randomization_factor = optional(number, null)
    }), {})
    role_definitions = optional(object({
      error_message_regex = optional(list(string), [
        "AuthorizationFailed" # Avoids a eventual consistency issue where a recently created management group is not yet available for a GET operation.
      ])
      interval_seconds     = optional(number, null)
      max_interval_seconds = optional(number, null)
      multiplier           = optional(number, null)
      randomization_factor = optional(number, null)
    }), {})
    policy_definitions = optional(object({
      error_message_regex = optional(list(string), [
        "AuthorizationFailed" # Avoids a eventual consistency issue where a recently created management group is not yet available for a GET operation.
      ])
      interval_seconds     = optional(number, null)
      max_interval_seconds = optional(number, null)
      multiplier           = optional(number, null)
      randomization_factor = optional(number, null)
    }), {})
    policy_set_definitions = optional(object({
      error_message_regex = optional(list(string), [
        "AuthorizationFailed" # Avoids a eventual consistency issue where a recently created management group is not yet available for a GET operation.
      ])
      interval_seconds     = optional(number, null)
      max_interval_seconds = optional(number, null)
      multiplier           = optional(number, null)
      randomization_factor = optional(number, null)
    }), {})
    policy_assignments = optional(object({
      error_message_regex = optional(list(string), [
        "AuthorizationFailed",                                                      # Avoids a eventual consistency issue where a recently created management group is not yet available for a GET operation.
        "The policy definition specified in policy assignment '.+' is out of scope" # If assignment is created soon after a policy definition has been created then the assignment will fail with this error.
      ])
      interval_seconds     = optional(number, 5)
      max_interval_seconds = optional(number, 30)
      multiplier           = optional(number, null)
      randomization_factor = optional(number, null)
    }), {})
    policy_role_assignments = optional(object({
      error_message_regex = optional(list(string), [
        "AuthorizationFailed", # Avoids a eventual consistency issue where a recently created management group is not yet available for a GET operation.
        "ResourceNotFound",    # If the resource has just been created, retry until it is available.
      ])
      interval_seconds     = optional(number, null)
      max_interval_seconds = optional(number, null)
      multiplier           = optional(number, null)
      randomization_factor = optional(number, null)
    }), {})
    hierarchy_settings = optional(object({
      error_message_regex  = optional(list(string), null)
      interval_seconds     = optional(number, null)
      max_interval_seconds = optional(number, null)
      multiplier           = optional(number, null)
      randomization_factor = optional(number, null)
    }), {})
    subscription_placement = optional(object({
      error_message_regex = optional(list(string), [
        "AuthorizationFailed", # Avoids a eventual consistency issue where a recently created management group is not yet available for a GET operation.
      ])
      interval_seconds     = optional(number, null)
      max_interval_seconds = optional(number, null)
      multiplier           = optional(number, null)
      randomization_factor = optional(number, null)
    }), {})
  })
  default     = {}
  description = <<DESCRIPTION
The retry settings to apply to the CRUD operations. Value is a nested object, the top level keys are the resources and the values are an object with the following attributes:

- `error_message_regex` - (Optional) A list of error message regexes to retry on. Defaults to `null`, which will will disable retries. Specify a value to enable.
- `interval_seconds` - (Optional) The initial interval in seconds between retries. Defaults to `null` and will fall back to the provider default value.
- `max_interval_seconds` - (Optional) The maximum interval in seconds between retries. Defaults to `null` and will fall back to the provider default value.
- `multiplier` - (Optional) The multiplier to apply to the interval between retries. Defaults to `null` and will fall back to the provider default value.
- `randomization_factor` - (Optional) The randomization factor to apply to the interval between retries. Defaults to `null` and will fall back to the provider default value.

For more information please see the provider documentation here: <https://registry.terraform.io/providers/Azure/azapi/azurerm/latest/docs/resources/resource#nestedatt--retry>
DESCRIPTION
}

variable "timeouts" {
  type = object({
    management_group = optional(object({
      create = optional(string, "5m")
      delete = optional(string, "5m")
      update = optional(string, "5m")
      read   = optional(string, "5m")
      }), {}
    )
    role_definition = optional(object({
      create = optional(string, "5m")
      delete = optional(string, "5m")
      update = optional(string, "5m")
      read   = optional(string, "5m")
      }), {}
    )
    policy_definition = optional(object({
      create = optional(string, "5m")
      delete = optional(string, "5m")
      update = optional(string, "5m")
      read   = optional(string, "5m")
      }), {}
    )
    policy_set_definition = optional(object({
      create = optional(string, "5m")
      delete = optional(string, "5m")
      update = optional(string, "5m")
      read   = optional(string, "5m")
      }), {}
    )
    policy_assignment = optional(object({
      create = optional(string, "15m") # Set high to allow consolidation of policy definitions coming into scope
      delete = optional(string, "5m")
      update = optional(string, "5m")
      read   = optional(string, "5m")
      }), {}
    )
    policy_role_assignment = optional(object({
      create = optional(string, "5m")
      delete = optional(string, "5m")
      update = optional(string, "5m")
      read   = optional(string, "5m")
      }), {}
    )
  })
  default     = {}
  description = <<DESCRIPTION
A map of timeouts to apply to the creation and destruction of resources.
If using retry, the maximum elapsed retry time is governed by this value.

The object has attributes for each resource type, with the following optional attributes:

- `create` - (Optional) The timeout for creating the resource. Defaults to `5m` apart from policy assignments, where this is set to `15m`.
- `delete` - (Optional) The timeout for deleting the resource. Defaults to `5m`.
- `update` - (Optional) The timeout for updating the resource. Defaults to `5m`.
- `read` - (Optional) The timeout for reading the resource. Defaults to `5m`.

Each time duration is parsed using this function: <https://pkg.go.dev/time#ParseDuration>.
DESCRIPTION
}
