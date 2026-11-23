data "aws_caller_identity" "current" {}

data "aws_ssoadmin_instances" "this" {}

data "terraform_remote_state" "org" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = "00-org/terraform.tfstate"
    region = var.state_region
  }
}

data "aws_ssoadmin_permission_set" "administrator" {
  instance_arn = local.instance_arn
  name         = "AdministratorAccess"
}

locals {
  instance_arn      = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]

  accounts = merge(
    { management = data.aws_caller_identity.current.account_id },
    data.terraform_remote_state.org.outputs.account_ids,
  )
}
