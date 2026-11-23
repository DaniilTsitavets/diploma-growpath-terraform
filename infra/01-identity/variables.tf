variable "region" {
  description = "Region of the IAM Identity Center instance."
  type        = string
  default     = "us-east-1"
}

variable "state_bucket" {
  description = "S3 bucket that holds Terraform state, also used to read 00-org outputs."
  type        = string
}

variable "state_region" {
  description = "Region of the state bucket."
  type        = string
  default     = "eu-north-1"
}

variable "github_repository_subject" {
  description = "Repository part of the GitHub OIDC subject claim, in the immutable owner@ownerId/repo@repoId form."
  type        = string
  default     = "DaniilTsitavets@175641668/diploma-growpath-terraform@1468996059"
}

variable "github_apply_environment" {
  description = "GitHub environment whose jobs may assume the apply role."
  type        = string
  default     = "management"
}

variable "experts_access" {
  description = "Permission set granted to the experts group on every account."
  type        = string
  default     = "administrator"

  validation {
    condition     = contains(["administrator", "readonly"], var.experts_access)
    error_message = "experts_access must be administrator or readonly."
  }
}
