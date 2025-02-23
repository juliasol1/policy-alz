output "policy_assignment_resource_ids" {
  description = "A map of policy assignment names to their resource ids."
  value       = { for k, v in azapi_resource.policy_assignments : k => v.id }
}

output "policy_definition_resource_ids" {
  description = "A map of policy definition names to their resource ids."
  value       = { for k, v in azapi_resource.policy_definitions : k => v.id }
}

output "policy_set_definition_resource_ids" {
  description = "A map of policy set definition names to their resource ids."
  value       = { for k, v in azapi_resource.policy_set_definitions : k => v.id }
}


