module "network_access" {
  source = "../modules/github-ci-access"

  providers = {
    aws = aws.network
  }

  github_repository_subject = var.github_repository_subject
  apply_environment         = var.apply_environments["network"]
  state_bucket              = var.state_bucket
}

module "prod_access" {
  source = "../modules/github-ci-access"

  providers = {
    aws = aws.prod
  }

  github_repository_subject = var.github_repository_subject
  apply_environment         = var.apply_environments["prod"]
  state_bucket              = var.state_bucket
  assumable_role_arns       = ["arn:aws:iam::${local.account_ids["network"]}:role/NetworkReader"]
  additional_read_actions   = ["s3vectors:Get*", "s3vectors:List*"]
}
