module "frontend_ci_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "~> 6.11"

  name            = "GitHubActionsFrontendDeploy"
  use_name_prefix = false

  enable_github_oidc = true
  oidc_subjects      = ["${var.frontend_repository_subject}:environment:${var.ci_environment}"]

  create_inline_policy = true
  inline_policy_permissions = {
    SyncBucket = {
      actions = ["s3:ListBucket", "s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
      resources = [
        module.s3_frontend.s3_bucket_arn,
        "${module.s3_frontend.s3_bucket_arn}/*",
      ]
    }
    Invalidate = {
      actions   = ["cloudfront:CreateInvalidation"]
      resources = [module.cdn.cloudfront_distribution_arn]
    }
  }
}

module "backend_ci_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "~> 6.11"

  name            = "GitHubActionsBackendPush"
  use_name_prefix = false

  enable_github_oidc = true
  oidc_subjects      = ["${var.backend_repository_subject}:environment:${var.ci_environment}"]

  create_inline_policy = true
  inline_policy_permissions = {
    EcrLogin = {
      actions   = ["ecr:GetAuthorizationToken"]
      resources = ["*"]
    }
    EcrPush = {
      actions = [
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:CompleteLayerUpload",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart",
      ]
      resources = [for repo in module.ecr : repo.repository_arn]
    }
  }
}
