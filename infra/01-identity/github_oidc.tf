resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

locals {
  github_sub_apply = "repo:${var.github_repository_subject}:environment:${var.github_apply_environment}"
  github_sub_pr    = "repo:${var.github_repository_subject}:pull_request"
}

data "aws_iam_policy_document" "apply_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.github_sub_apply]
    }
  }
}

data "aws_iam_policy_document" "plan_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.github_sub_pr]
    }
  }
}

resource "aws_iam_role" "github_apply" {
  name                 = "GitHubActionsApplyRole"
  assume_role_policy   = data.aws_iam_policy_document.apply_trust.json
  max_session_duration = 3600
}

resource "aws_iam_role_policy_attachment" "github_apply" {
  role       = aws_iam_role.github_apply.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

data "aws_iam_policy_document" "plan_state_lock" {
  statement {
    actions   = ["s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::${var.state_bucket}/*.tflock"]
  }
}

resource "aws_iam_role" "github_plan" {
  name                 = "GitHubActionsPlanRole"
  assume_role_policy   = data.aws_iam_policy_document.plan_trust.json
  max_session_duration = 3600
}

resource "aws_iam_role_policy_attachment" "github_plan" {
  role       = aws_iam_role.github_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role_policy" "github_plan_state_lock" {
  name   = "state-lock"
  role   = aws_iam_role.github_plan.id
  policy = data.aws_iam_policy_document.plan_state_lock.json
}
