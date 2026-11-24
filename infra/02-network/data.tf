data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "terraform_remote_state" "org" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = "00-org/terraform.tfstate"
    region = "eu-north-1"
  }
}

locals {
  azs                 = slice(data.aws_availability_zones.available.names, 0, 3)
  prod_account_id     = data.terraform_remote_state.org.outputs.account_ids["prod"]
  prod_apply_role_arn = "arn:aws:iam::${local.prod_account_id}:role/GitHubActionsApplyRole"
  prod_plan_role_arn  = "arn:aws:iam::${local.prod_account_id}:role/GitHubActionsPlanRole"
  external_dns_role   = "arn:aws:iam::${local.prod_account_id}:role/growpath-external-dns"
}
