locals {
  topics = toset(["order-placed", "ticket-events", "escalation-requested"])

  # Queue ARNs are known only after the queue exists and the queue policy needs the topic ARN,
  # so the topic ARNs are built from names to avoid a module cycle.
  topic_arns = {
    for name in local.topics :
    name => "arn:aws:sns:${var.region}:${data.aws_caller_identity.current.account_id}:${name}"
  }

  queues = {
    entitlement-order-placed = {
      topic = "order-placed"
    }
    plant-care-order-placed = {
      topic = "order-placed"
    }
    entitlement-ticket-events = {
      topic         = "ticket-events"
      filter_policy = jsonencode({ event_type = ["ticket.created", "ticket.cancelled"] })
    }
    plant-care-ticket-events = {
      topic = "ticket-events"
    }
    expert-escalation-requested = {
      topic = "escalation-requested"
    }
  }
}

module "queue" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "~> 5.2"

  for_each = local.queues

  name = each.key

  visibility_timeout_seconds = 30
  receive_wait_time_seconds  = 5

  create_dlq                    = true
  dlq_name                      = "${each.key}-dlq"
  dlq_message_retention_seconds = 1209600
  redrive_policy = {
    maxReceiveCount = 5
  }

  create_queue_policy = true
  queue_policy_statements = {
    sns = {
      sid       = "AllowTopicPublish"
      actions   = ["sqs:SendMessage"]
      resources = ["arn:aws:sqs:${var.region}:${data.aws_caller_identity.current.account_id}:${each.key}"]
      principals = [{
        type        = "Service"
        identifiers = ["sns.amazonaws.com"]
      }]
      condition = [{
        test     = "ArnEquals"
        variable = "aws:SourceArn"
        values   = [local.topic_arns[each.value.topic]]
      }]
    }
  }
}

module "topic" {
  source  = "terraform-aws-modules/sns/aws"
  version = "~> 7.2"

  for_each = local.topics

  name = each.key

  subscriptions = {
    for queue, spec in local.queues : queue => {
      protocol             = "sqs"
      endpoint             = module.queue[queue].queue_arn
      raw_message_delivery = true
      filter_policy        = try(spec.filter_policy, null)
    } if spec.topic == each.key
  }
}
