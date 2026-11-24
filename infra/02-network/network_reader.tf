module "network_reader" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "~> 6.11"

  name            = "NetworkReader"
  use_name_prefix = false

  trust_policy_permissions = {
    ProdPlan = {
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "AWS"
        identifiers = [local.prod_plan_role_arn]
      }]
    }
  }

  policies = {
    ReadOnlyAccess = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  }
}
