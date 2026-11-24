module "oidc_provider" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-oidc-provider"
  version = "~> 6.11"
}

module "apply_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "~> 6.11"

  name                 = "GitHubActionsApplyRole"
  use_name_prefix      = false
  max_session_duration = 3600

  enable_github_oidc = true
  oidc_subjects      = ["${var.github_repository_subject}:environment:${var.apply_environment}"]

  policies = {
    AdministratorAccess = "arn:aws:iam::aws:policy/AdministratorAccess"
  }

  depends_on = [module.oidc_provider]
}

module "plan_role" {
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
  inline_policy_permissions = merge(
    {
      StateLock = {
        actions   = ["s3:PutObject", "s3:DeleteObject"]
        resources = ["arn:aws:s3:::${var.state_bucket}/*.tflock"]
      }
    },
    length(var.assumable_role_arns) > 0 ? {
      AssumeRoles = {
        actions   = ["sts:AssumeRole"]
        resources = var.assumable_role_arns
      }
    } : {},
  )

  depends_on = [module.oidc_provider]
}
