terraform {
  backend "s3" {
    key          = "02-network/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
