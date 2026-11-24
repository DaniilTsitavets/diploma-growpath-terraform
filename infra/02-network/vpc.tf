module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.8"

  name = "growpath-network"
  cidr = var.vpc_cidr
  azs  = [local.azs[0]]

  public_subnets = [cidrsubnet(var.vpc_cidr, 2, 0)]

  enable_nat_gateway   = false
  enable_dns_support   = true
  enable_dns_hostnames = true

  manage_default_security_group  = true
  default_security_group_ingress = []
  default_security_group_egress  = []
}
