variable "region" {
  description = "Region of the member account resources."
  type        = string
  default     = "eu-north-1"
}

variable "state_bucket" {
  description = "S3 bucket that holds Terraform state in the management account."
  type        = string
}

variable "github_repository_subject" {
  description = "Repository part of the GitHub OIDC subject claim, in the immutable owner@ownerId/repo@repoId form."
  type        = string
  default     = "DaniilTsitavets@175641668/diploma-growpath-terraform@1468996059"
}

variable "apply_environments" {
  description = "GitHub environment per account whose jobs may assume that account's apply role."
  type        = map(string)
  default = {
    network = "network"
    prod    = "prod"
  }
}
