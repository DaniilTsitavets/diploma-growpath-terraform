module "vpc_link_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 6.0"

  name        = "growpath-apigw-vpclink"
  description = "API Gateway VPC link network interfaces"
  vpc_id      = module.vpc.vpc_id

  egress_rules = {
    to_alb = {
      description = "HTTP to the internal ALB"
      cidr_ipv4   = module.vpc.vpc_cidr_block
      from_port   = 80
      to_port     = 80
    }
  }
}

module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 6.0"

  name        = "growpath-alb"
  description = "Internal ALB that fronts the services"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = {
    from_vpc_link = {
      description                  = "HTTP from the API Gateway VPC link"
      referenced_security_group_id = module.vpc_link_sg.id
      from_port                    = 80
      to_port                      = 80
    }
  }

  egress_rules = {
    to_pods = {
      description = "Traffic to pods in the VPC"
      cidr_ipv4   = module.vpc.vpc_cidr_block
      ip_protocol = "-1"
    }
  }
}
