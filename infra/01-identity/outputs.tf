output "github_apply_role_arn" {
  description = "Role assumed by GitHub Actions on pushes to main."
  value       = aws_iam_role.github_apply.arn
}

output "github_plan_role_arn" {
  description = "Read-only role assumed by GitHub Actions on pull requests."
  value       = aws_iam_role.github_plan.arn
}

output "experts_group_id" {
  description = "Identity Store ID of the experts group."
  value       = aws_identitystore_group.experts.group_id
}

output "readonly_permission_set_arn" {
  description = "ARN of the ReadOnlyAccess permission set."
  value       = aws_ssoadmin_permission_set.readonly.arn
}
