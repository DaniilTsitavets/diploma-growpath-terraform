output "network_roles" {
  description = "CI role ARNs in the network account."
  value = {
    apply = module.network_access.apply_role_arn
    plan  = module.network_access.plan_role_arn
  }
}

output "prod_roles" {
  description = "CI role ARNs in the prod account."
  value = {
    apply = module.prod_access.apply_role_arn
    plan  = module.prod_access.plan_role_arn
  }
}
