terraform {
  backend "s3" {
    key          = "03-prod/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
