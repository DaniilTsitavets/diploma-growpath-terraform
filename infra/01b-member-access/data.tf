data "terraform_remote_state" "org" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = "00-org/terraform.tfstate"
    region = "eu-north-1"
  }
}

locals {
  account_ids = data.terraform_remote_state.org.outputs.account_ids
}
