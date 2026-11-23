resource "aws_organizations_policy" "region_restriction" {
  name        = "AdvancedModeRegionRestrictionSecurityControlPolicy"
  description = "AdvancedModeRegionRestrictionSecurityControlPolicy"
  type        = "SERVICE_CONTROL_POLICY"
  content     = file("${path.module}/policies/region-restriction.json")

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_policy_attachment" "region_restriction_root" {
  policy_id = aws_organizations_policy.region_restriction.id
  target_id = local.root_id
}

resource "aws_organizations_policy" "managed_account_security" {
  name        = "ManagedAccountSecurityControlPolicy"
  description = "ManagedAccountSecurityControlPolicy"
  type        = "SERVICE_CONTROL_POLICY"
  content     = file("${path.module}/policies/managed-account-security.json")

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_policy_attachment" "managed_account_security_root" {
  policy_id = aws_organizations_policy.managed_account_security.id
  target_id = local.root_id
}

resource "aws_organizations_policy" "deny_cloudtrail_disable" {
  name        = "DenyCloudTrailDisable"
  description = "Denies stopping, deleting and reconfiguring CloudTrail"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "DenyCloudTrailDisable"
      Effect = "Deny"
      Action = [
        "cloudtrail:StopLogging",
        "cloudtrail:DeleteTrail",
        "cloudtrail:UpdateTrail",
        "cloudtrail:PutEventSelectors",
      ]
      Resource = "*"
    }]
  })
}

resource "aws_organizations_policy_attachment" "deny_cloudtrail_disable_root" {
  policy_id = aws_organizations_policy.deny_cloudtrail_disable.id
  target_id = local.root_id
}
