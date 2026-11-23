resource "aws_identitystore_group" "experts" {
  identity_store_id = local.identity_store_id
  display_name      = "diploma-experts"
  description       = "Diploma reviewers"
}

locals {
  experts_permission_set_arn = var.experts_access == "administrator" ? data.aws_ssoadmin_permission_set.administrator.arn : aws_ssoadmin_permission_set.readonly.arn
}

resource "aws_ssoadmin_account_assignment" "experts" {
  for_each = local.accounts

  instance_arn       = local.instance_arn
  permission_set_arn = local.experts_permission_set_arn
  principal_id       = aws_identitystore_group.experts.group_id
  principal_type     = "GROUP"
  target_id          = each.value
  target_type        = "AWS_ACCOUNT"

  depends_on = [aws_ssoadmin_managed_policy_attachment.readonly]
}
