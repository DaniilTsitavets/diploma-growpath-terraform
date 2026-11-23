locals {
  state_access = {
    network = {
      apply_role = module.network_access.apply_role_arn
      plan_role  = module.network_access.plan_role_arn
      own_prefix = "02-network"
      read_keys  = ["00-org/terraform.tfstate"]
    }
    prod = {
      apply_role = module.prod_access.apply_role_arn
      plan_role  = module.prod_access.plan_role_arn
      own_prefix = "03-prod"
      read_keys  = ["00-org/terraform.tfstate", "02-network/terraform.tfstate"]
    }
  }

  bucket_arn = "arn:aws:s3:::${var.state_bucket}"
}

data "aws_iam_policy_document" "state_bucket" {
  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [local.bucket_arn, "${local.bucket_arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid       = "ListBucket"
    actions   = ["s3:ListBucket"]
    resources = [local.bucket_arn]

    principals {
      type = "AWS"
      identifiers = flatten([
        for a in local.state_access : [a.apply_role, a.plan_role]
      ])
    }
  }

  dynamic "statement" {
    for_each = local.state_access

    content {
      sid       = "Read${title(statement.key)}"
      actions   = ["s3:GetObject"]
      resources = [for k in concat(statement.value.read_keys, ["${statement.value.own_prefix}/terraform.tfstate"]) : "${local.bucket_arn}/${k}"]

      principals {
        type        = "AWS"
        identifiers = [statement.value.apply_role, statement.value.plan_role]
      }
    }
  }

  dynamic "statement" {
    for_each = local.state_access

    content {
      sid       = "Apply${title(statement.key)}"
      actions   = ["s3:PutObject", "s3:DeleteObject"]
      resources = ["${local.bucket_arn}/${statement.value.own_prefix}/*"]

      principals {
        type        = "AWS"
        identifiers = [statement.value.apply_role]
      }
    }
  }

  dynamic "statement" {
    for_each = local.state_access

    content {
      sid       = "PlanLock${title(statement.key)}"
      actions   = ["s3:PutObject", "s3:DeleteObject"]
      resources = ["${local.bucket_arn}/${statement.value.own_prefix}/*.tflock"]

      principals {
        type        = "AWS"
        identifiers = [statement.value.plan_role]
      }
    }
  }
}

resource "aws_s3_bucket_policy" "state" {
  bucket = var.state_bucket
  policy = data.aws_iam_policy_document.state_bucket.json
}
