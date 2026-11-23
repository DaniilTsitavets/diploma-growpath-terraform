resource "aws_organizations_organization" "this" {
  feature_set = "ALL"

  aws_service_access_principals = [
    "account-access.amazonaws.com",
    "account.amazonaws.com",
    "cloudtrail.amazonaws.com",
    "compute-optimizer.amazonaws.com",
    "cost-optimization-hub.bcm.amazonaws.com",
    "guardduty.amazonaws.com",
    "iam.amazonaws.com",
    "notifications.amazonaws.com",
    "sso.amazonaws.com",
  ]

  enabled_policy_types = [
    "RESOURCE_CONTROL_POLICY",
    "SERVICE_CONTROL_POLICY",
  ]

  lifecycle {
    prevent_destroy = true
  }
}

locals {
  root_id = aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_organizational_unit" "security" {
  name      = "Security"
  parent_id = local.root_id
}

resource "aws_organizations_organizational_unit" "infrastructure" {
  name      = "Infrastructure"
  parent_id = local.root_id
}

resource "aws_organizations_organizational_unit" "workloads" {
  name      = "Workloads"
  parent_id = local.root_id
}
