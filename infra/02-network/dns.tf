module "zone" {
  source  = "terraform-aws-modules/route53/aws"
  version = "~> 6.5"

  name    = var.domain_name
  comment = "Public zone of the GrowPath platform"
}

module "dns_record_writer" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "~> 6.11"

  name            = "DnsRecordWriter"
  use_name_prefix = false

  trust_policy_permissions = {
    ProdApply = {
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "AWS"
        identifiers = [local.prod_apply_role_arn]
      }]
    }
    ExternalDns = {
      actions = ["sts:AssumeRole"]
      # Account root plus a condition, so the apply order of the layers does not matter.
      principals = [{
        type        = "AWS"
        identifiers = ["arn:aws:iam::${local.prod_account_id}:root"]
      }]
      condition = [{
        test     = "ArnEquals"
        variable = "aws:PrincipalArn"
        values   = [local.external_dns_role]
      }]
    }
  }

  create_inline_policy = true
  inline_policy_permissions = {
    ZoneRecords = {
      actions   = ["route53:ChangeResourceRecordSets", "route53:ListResourceRecordSets", "route53:GetHostedZone"]
      resources = [module.zone.arn]
    }
    Changes = {
      actions   = ["route53:GetChange"]
      resources = ["arn:aws:route53:::change/*"]
    }
    Zones = {
      actions   = ["route53:ListHostedZones", "route53:ListHostedZonesByName"]
      resources = ["*"]
    }
  }
}
