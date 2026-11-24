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
  default     = false
}

variable "services" {
  description = "Backend services that get an ECR repository."
  type        = list(string)
  default     = ["commerce", "entitlement", "plant-care", "expert-consultation"]
}

variable "domain_name" {
  description = "Public domain of the platform."
  type        = string
}

variable "enable_api_routes" {
  description = "Create the API Gateway routes once the internal ALB exists (second phase of the ingress deployment)."
  type        = bool
  default     = false
}

variable "api_throttling_rate_limit" {
  description = "Steady request rate per second allowed on every route."
  type        = number
  default     = 20
}

variable "api_throttling_burst_limit" {
  description = "Burst of requests allowed on every route."
  type        = number
  default     = 40
}

variable "dns_role_arn" {
  description = "Role in the network account that manages records of the public DNS zone."
  type        = string
}

variable "frontend_repository_subject" {
  description = "Frontend repository part of the GitHub OIDC subject claim, in the immutable owner@ownerId/repo@repoId form."
  type        = string
}

variable "backend_repository_subject" {
  description = "Backend repository part of the GitHub OIDC subject claim, in the immutable owner@ownerId/repo@repoId form."
  type        = string
}

variable "ci_environment" {
  description = "GitHub environment, defined in the frontend and backend repositories, whose jobs may assume the deploy roles."
  type        = string
  default     = "prod"
}
