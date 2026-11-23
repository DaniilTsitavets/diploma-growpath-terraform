output "organization_id" {
  description = "Organization ID."
  value       = aws_organizations_organization.this.id
}

output "root_id" {
  description = "Organization root ID."
  value       = local.root_id
}

output "ou_ids" {
  description = "Organizational unit IDs."
  value = {
    security       = aws_organizations_organizational_unit.security.id
    infrastructure = aws_organizations_organizational_unit.infrastructure.id
    workloads      = aws_organizations_organizational_unit.workloads.id
  }
}

output "account_ids" {
  description = "Member account IDs."
  value = {
    logging = aws_organizations_account.logging.id
    network = aws_organizations_account.network.id
    prod    = aws_organizations_account.prod.id
  }
}
