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
  description = "CIDR block of the shared VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "cluster_name" {
  description = "EKS cluster name used for the Karpenter discovery subnet tag."
  type        = string
  default     = "growpath"
}

variable "tailscale_instance_type" {
  description = "Instance type of the Tailscale subnet router."
  type        = string
  default     = "t4g.nano"
}
