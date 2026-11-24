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

data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = "02-network/terraform.tfstate"
    region = "eu-north-1"
  }
}

locals {
  azs                  = slice(data.aws_availability_zones.available.names, 0, 3)
  network_account_id   = data.terraform_remote_state.org.outputs.account_ids["network"]
  network_vpc_id       = data.terraform_remote_state.network.outputs.vpc_id
  network_vpc_cidr     = data.terraform_remote_state.network.outputs.vpc_cidr_block
  network_public_rt_id = data.terraform_remote_state.network.outputs.public_route_table_id
}
