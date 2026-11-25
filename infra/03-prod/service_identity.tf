locals {
  service_namespace = "growpath-services"

  queue_arn = { for name, queue in module.queue : name => queue.queue_arn }

  consume_actions = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]

  service_statements = {
    commerce = [{
      sid       = "PublishOrderPlaced"
      actions   = ["sns:Publish"]
      resources = [local.topic_arns["order-placed"]]
    }]

    entitlement = [{
      sid       = "ConsumeQueues"
      actions   = local.consume_actions
      resources = [local.queue_arn["entitlement-order-placed"], local.queue_arn["entitlement-ticket-events"]]
    }]

    plant-care = [
      {
        sid       = "ConsumeQueues"
        actions   = local.consume_actions
        resources = [local.queue_arn["plant-care-order-placed"], local.queue_arn["plant-care-ticket-events"]]
      },
      {
        sid       = "PublishEscalation"
        actions   = ["sns:Publish"]
        resources = [local.topic_arns["escalation-requested"]]
      },
      {
        sid       = "Photos"
        actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        resources = ["${module.s3_photos.s3_bucket_arn}/journals/*"]
      },
    ]

    expert-consultation = [
      {
        sid       = "ConsumeQueue"
        actions   = local.consume_actions
        resources = [local.queue_arn["expert-escalation-requested"]]
      },
      {
        sid       = "PublishTicketEvents"
        actions   = ["sns:Publish"]
        resources = [local.topic_arns["ticket-events"]]
      },
      {
        sid       = "ReadPhotos"
        actions   = ["s3:GetObject"]
        resources = ["${module.s3_photos.s3_bucket_arn}/journals/*"]
      },
      {
        sid = "ManageExperts"
        actions = [
          "cognito-idp:AdminCreateUser",
          "cognito-idp:AdminGetUser",
          "cognito-idp:AdminListGroupsForUser",
          "cognito-idp:AdminAddUserToGroup",
          "cognito-idp:AdminRemoveUserFromGroup",
          "cognito-idp:AdminDisableUser",
          "cognito-idp:AdminEnableUser",
          "cognito-idp:AdminSetUserPassword",
          "cognito-idp:AdminDeleteUser",
          "cognito-idp:ListUsers",
          "cognito-idp:ListUsersInGroup",
        ]
        resources = [aws_cognito_user_pool.this.arn]
      },
    ]
  }
}

module "service_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.11"

  for_each = local.service_statements

  name            = "${var.cluster_name}-${each.key}"
  use_name_prefix = false

  attach_custom_policy = true
  policy_statements    = each.value

  associations = {
    this = {
      cluster_name    = module.eks.cluster_name
      namespace       = local.service_namespace
      service_account = each.key
    }
  }
}
