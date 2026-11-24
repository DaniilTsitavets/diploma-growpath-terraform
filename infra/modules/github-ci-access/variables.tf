variable "github_repository_subject" {
  description = "Repository part of the GitHub OIDC subject claim, in the immutable owner@ownerId/repo@repoId form."
  type        = string
}

variable "apply_environment" {
  description = "GitHub environment whose jobs may assume the apply role."
  type        = string
}

variable "state_bucket" {
  description = "Terraform state bucket (in the management account) the plan role writes lock files to."
  type        = string
}

variable "assumable_role_arns" {
  description = "Roles in other accounts that the plan role may assume."
  type        = list(string)
  default     = []
}

variable "additional_read_actions" {
  description = "Read-only actions of services that the managed ReadOnlyAccess policy does not cover yet."
  type        = list(string)
  default     = []
}
