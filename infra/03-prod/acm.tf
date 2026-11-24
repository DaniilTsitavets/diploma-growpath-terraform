module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 6.3"

  region                 = "us-east-1"
  domain_name            = var.domain_name
  validation_method      = "DNS"
  create_route53_records = false
  wait_for_validation    = false
}

resource "aws_route53_record" "acm_validation" {
  provider = aws.dns

  for_each = {
    for option in module.acm.acm_certificate_domain_validation_options : option.domain_name => option
  }

  zone_id         = local.zone_id
  name            = each.value.resource_record_name
  type            = each.value.resource_record_type
  records         = [each.value.resource_record_value]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "this" {
  region = "us-east-1"

  certificate_arn         = module.acm.acm_certificate_arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]
}
