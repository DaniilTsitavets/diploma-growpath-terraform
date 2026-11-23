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

variable "github_repository" {
  description = "GitHub repository (owner/name) allowed to assume the CI roles."
  type        = string
  default     = "DaniilTsitavets/diploma-growpath-terraform"
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
