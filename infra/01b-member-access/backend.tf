terraform {
  backend "s3" {
    key          = "01b-member-access/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
