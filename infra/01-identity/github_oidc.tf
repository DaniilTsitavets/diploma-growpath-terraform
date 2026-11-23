module "github_oidc_provider" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-oidc-provider"
  version = "~> 6.11"
}

module "github_apply_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "~> 6.11"

  name                 = "GitHubActionsApplyRole"
  use_name_prefix      = false
  max_session_duration = 3600

  enable_github_oidc = true
  oidc_subjects      = ["${var.github_repository_subject}:environment:${var.github_apply_environment}"]

  policies = {
    AdministratorAccess = "arn:aws:iam::aws:policy/AdministratorAccess"
  }

  depends_on = [module.github_oidc_provider]
}

module "github_plan_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "~> 6.11"

  name                 = "GitHubActionsPlanRole"
  use_name_prefix      = false
  max_session_duration = 3600

  enable_github_oidc = true
  oidc_subjects      = ["${var.github_repository_subject}:pull_request"]

  policies = {
    ReadOnlyAccess = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  }

  create_inline_policy = true
  inline_policy_permissions = {
    StateLock = {
      actions   = ["s3:PutObject", "s3:DeleteObject"]
      resources = ["arn:aws:s3:::${var.state_bucket}/*.tflock"]
    }
  }

  depends_on = [module.github_oidc_provider]
}

moved {
  from = aws_iam_openid_connect_provider.github
  to   = module.github_oidc_provider.aws_iam_openid_connect_provider.this[0]
}

moved {
  from = aws_iam_role.github_apply
  to   = module.github_apply_role.aws_iam_role.this[0]
}

moved {
  from = aws_iam_role_policy_attachment.github_apply
  to   = module.github_apply_role.aws_iam_role_policy_attachment.this["AdministratorAccess"]
}

moved {
  from = aws_iam_role.github_plan
  to   = module.github_plan_role.aws_iam_role.this[0]
}

moved {
  from = aws_iam_role_policy_attachment.github_plan
  to   = module.github_plan_role.aws_iam_role_policy_attachment.this["ReadOnlyAccess"]
}
