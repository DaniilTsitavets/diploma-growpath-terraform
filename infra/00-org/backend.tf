terraform {
  backend "s3" {
    key          = "00-org/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
