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
}
