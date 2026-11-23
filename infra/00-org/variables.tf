variable "region" {
  description = "Provider region."
  type        = string
  default     = "eu-north-1"
}

variable "account_emails" {
  description = "Unique root email per member account (keys: logging, network, prod)."
  type        = map(string)

  validation {
    condition     = alltrue([for k in ["logging", "network", "prod"] : contains(keys(var.account_emails), k)])
    error_message = "account_emails must contain the keys logging, network and prod."
  }
}

variable "budget_notification_email" {
  description = "Email that receives AWS Budgets notifications."
  type        = string
}

variable "monthly_budget_usd" {
  description = "Monthly cost limit for the whole organization, USD."
  type        = number
  default     = 70
}
