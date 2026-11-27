locals {
  service_namespace = "growpath-services"

  queue_arn = { for name, queue in module.queue : name => queue.queue_arn }

  consume_actions = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]

  # The EU geo inference profile fans a request out to these regions, so the model has to be allowed in each of them.
  bedrock_model_id    = "anthropic.claude-haiku-5-5"
  bedrock_regions     = ["eu-north-1", "eu-west-1", "eu-west-3", "eu-central-1", "eu-south-1", "eu-south-2"]
  bedrock_profile_arn = "arn:aws:bedrock:${var.region}:${data.aws_caller_identity.current.account_id}:inference-profile/eu.${local.bedrock_model_id}"
  bedrock_actions     = ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"]

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
      {
        sid       = "InvokeModelProfile"
        actions   = local.bedrock_actions
        resources = [local.bedrock_profile_arn]
      },
      {
        sid       = "InvokeModelBehindProfile"
        actions   = local.bedrock_actions
        resources = [for region in local.bedrock_regions : "arn:aws:bedrock:${region}::foundation-model/${local.bedrock_model_id}"]
        condition = [{
          test     = "StringEquals"
          variable = "bedrock:InferenceProfileArn"
          values   = [local.bedrock_profile_arn]
        }]
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

  associations = { for cluster in module.eks[*].cluster_name : "this" => {
    cluster_name    = cluster
    namespace       = local.service_namespace
    service_account = each.key
  } }
}
