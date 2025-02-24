locals {
  policy_definitions = {
    for pdval in flatten([
      for mg in data.alz_architecture.this.management_groups : [
        for pdname, pd in mg.policy_definitions : {
          key        = pdname
          definition = jsondecode(pd)
          mg         = mg.id
        }
      ]
  ]) : "${pdval.mg}/${pdval.key}" => pdval }
}

# locals {
#   policy_set_definitions = {
#     for psdval in flatten([
#       for mg in data.alz_architecture.this.management_groups : [
#         for psdname, psd in mg.policy_set_definitions : {
#           key            = psdname
#           set_definition = jsondecode(psd)
#           mg             = mg.id
#         }
#       ]
#   ]) : "${psdval.mg}/${psdval.key}" => psdval }

# }

# locals {
#   policy_assignments = {
#     for paval in flatten([
#       for mg in data.alz_architecture.this.management_groups : [
#         for paname, pa in mg.policy_assignments : {
#           key        = paname
#           assignment = jsondecode(pa)
#           mg         = mg.id
#         }
#       ]
#   ]) : "${paval.mg}/${paval.key}" => paval }
# }

locals {
  policy_assignments = {
    for paval in flatten([
      for mg in data.alz_architecture.this.management_groups : [
        for paname, pa in mg.policy_assignments : {
          key        = paname
          assignment = jsondecode(pa)
          mg         = mg.id
        }
      ]
  # ]) : "julia/${paval.key /}" => paval }
  ]) : "${paval.mg}/${paval.key}" => paval }
}

locals {
  policy_assignment_identities = {
    for k, v in azapi_resource.policy_assignments : k => try(v.identity[0], null)
  }
}

