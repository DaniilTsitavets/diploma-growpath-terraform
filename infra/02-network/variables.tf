variable "region" {
  description = "Region of the network resources."
  type        = string
  default     = "eu-north-1"
}

variable "state_bucket" {
  description = "S3 bucket that holds Terraform state in the management account."
  type        = string
}

variable "domain_name" {
  description = "Public domain served by the Route53 zone."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the network VPC; must not overlap with the prod VPC."
  type        = string
  default     = "10.255.0.0/24"
}

variable "advertise_routes" {
  description = "CIDR blocks the Tailscale router advertises to the tailnet."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "tailscale_instance_type" {
  description = "Instance type of the Tailscale subnet router."
  type        = string
  default     = "t4g.nano"
}
