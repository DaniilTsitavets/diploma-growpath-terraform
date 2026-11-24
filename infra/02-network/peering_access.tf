data "aws_caller_identity" "current" {}

module "vpc_peering_manager" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "~> 6.11"

  name            = "VpcPeeringManager"
  use_name_prefix = false

  trust_policy_permissions = {
    ProdApply = {
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "AWS"
        identifiers = [local.prod_apply_role_arn]
      }]
    }
  }

  create_inline_policy = true
  inline_policy_permissions = {
    Peering = {
      actions = [
        "ec2:AcceptVpcPeeringConnection",
        "ec2:DeleteVpcPeeringConnection",
        "ec2:ModifyVpcPeeringConnectionOptions",
        "ec2:CreateTags",
        "ec2:DeleteTags",
      ]
      resources = ["*"]
    }
    Routes = {
      actions = ["ec2:CreateRoute", "ec2:DeleteRoute", "ec2:ReplaceRoute"]
      resources = [
        for id in module.vpc.public_route_table_ids :
        "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:route-table/${id}"
      ]
    }
    Describe = {
      actions   = ["ec2:Describe*"]
      resources = ["*"]
    }
  }
}
