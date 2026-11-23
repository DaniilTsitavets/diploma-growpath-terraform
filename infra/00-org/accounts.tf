resource "aws_organizations_account" "logging" {
  name              = "logging"
  email             = var.account_emails["logging"]
  parent_id         = aws_organizations_organizational_unit.security.id
  close_on_deletion = false

  lifecycle {
    ignore_changes = [role_name, iam_user_access_to_billing]
  }
}

resource "aws_organizations_account" "network" {
  name              = "network"
  email             = var.account_emails["network"]
  parent_id         = aws_organizations_organizational_unit.infrastructure.id
  close_on_deletion = false

  lifecycle {
    ignore_changes = [role_name, iam_user_access_to_billing]
  }
}

resource "aws_organizations_account" "prod" {
  name              = "prod"
  email             = var.account_emails["prod"]
  parent_id         = aws_organizations_organizational_unit.workloads.id
  close_on_deletion = false

  lifecycle {
    ignore_changes = [role_name, iam_user_access_to_billing]
  }
}
