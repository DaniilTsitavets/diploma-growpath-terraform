output "apply_role_arn" {
  description = "ARN of the apply role."
  value       = module.apply_role.arn
}

output "plan_role_arn" {
  description = "ARN of the plan role."
  value       = module.plan_role.arn
}
