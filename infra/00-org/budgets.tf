resource "aws_budgets_budget" "monthly" {
  name         = "growpath-monthly"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_types {
    include_credit = false
    include_refund = false
  }

  dynamic "notification" {
    for_each = {
      actual_50      = { threshold = 50, type = "ACTUAL" }
      actual_80      = { threshold = 80, type = "ACTUAL" }
      forecasted_100 = { threshold = 100, type = "FORECASTED" }
    }

    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = notification.value.threshold
      threshold_type             = "PERCENTAGE"
      notification_type          = notification.value.type
      subscriber_email_addresses = [var.budget_notification_email]
    }
  }
}
