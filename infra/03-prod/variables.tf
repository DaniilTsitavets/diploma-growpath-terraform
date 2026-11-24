variable "region" {
  description = "Region of the prod resources."
  type        = string
  default     = "eu-north-1"
}

variable "state_bucket" {
  description = "S3 bucket that holds Terraform state in the management account."
  type        = string
}

variable "network_role_arn" {
  description = "Role in the network account that manages the VPC peering and its routes."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the prod VPC; must not overlap with the network VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "cluster_name" {
  description = "EKS cluster name used for the Karpenter discovery subnet tag."
  type        = string
  default     = "growpath"
}

variable "enable_nat_gateway" {
  description = "Create the NAT gateway; turn it off to stop paying for it while the cluster is down."
  type        = bool
  default     = true
}
