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

  # Keyed by the known host names, because the validation options are only known after apply.
  for_each = toset(local.platform_fqdns)

  zone_id = local.zone_id
  name = one([
    for option in module.platform_acm.acm_certificate_domain_validation_options : option.resource_record_name
    if option.domain_name == each.key
  ])
  type = one([
    for option in module.platform_acm.acm_certificate_domain_validation_options : option.resource_record_type
    if option.domain_name == each.key
  ])
  records = [one([
    for option in module.platform_acm.acm_certificate_domain_validation_options : option.resource_record_value
    if option.domain_name == each.key
  ])]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "platform" {
  certificate_arn         = module.platform_acm.acm_certificate_arn
  validation_record_fqdns = [for record in aws_route53_record.platform_acm_validation : record.fqdn]
}
