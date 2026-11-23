terraform {
  backend "s3" {
    key          = "01-identity/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
