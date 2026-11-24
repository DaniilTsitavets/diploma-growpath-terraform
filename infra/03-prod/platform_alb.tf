locals {
  platform_fqdns = [for host in var.platform_hosts : "${host}.${var.domain_name}"]
}

module "platform_alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 6.0"

  name        = "growpath-admin-tools-alb"
  description = "Internal ALB for the platform tools, reached over Tailscale"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = {
    https_from_tailscale = {
      description = "HTTPS from the Tailscale router"
      cidr_ipv4   = local.network_vpc_cidr
      from_port   = 443
      to_port     = 443
    }
    http_from_tailscale = {
      description = "HTTP from the Tailscale router, only redirected to HTTPS"
      cidr_ipv4   = local.network_vpc_cidr
      from_port   = 80
      to_port     = 80
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

# ALB listeners need a certificate from the ALB region, unlike the CloudFront one in us-east-1.
module "platform_acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 6.3"

  domain_name               = local.platform_fqdns[0]
  subject_alternative_names = slice(local.platform_fqdns, 1, length(local.platform_fqdns))
  validation_method         = "DNS"
  create_route53_records    = false
  wait_for_validation       = false
}

resource "aws_route53_record" "platform_acm_validation" {
  provider = aws.dns

  for_each = {
    for option in module.platform_acm.acm_certificate_domain_validation_options : option.domain_name => option
  }

  zone_id         = local.zone_id
  name            = each.value.resource_record_name
  type            = each.value.resource_record_type
  records         = [each.value.resource_record_value]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "platform" {
  certificate_arn         = module.platform_acm.acm_certificate_arn
  validation_record_fqdns = [for record in aws_route53_record.platform_acm_validation : record.fqdn]
}

data "aws_lb" "platform" {
  count = var.enable_platform_dns ? 1 : 0

  tags = {
    "ingress-name" = "admin-tools"
  }
}

resource "aws_route53_record" "platform" {
  provider = aws.dns

  for_each = var.enable_platform_dns ? toset(local.platform_fqdns) : toset([])

  zone_id = local.zone_id
  name    = each.value
  type    = "A"

  alias {
    name                   = data.aws_lb.platform[0].dns_name
    zone_id                = data.aws_lb.platform[0].zone_id
    evaluate_target_health = true
  }
}
