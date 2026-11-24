data "aws_lb" "ingress" {
  count = var.enable_api_routes ? 1 : 0

  tags = {
    "ingress-name" = "growpath"
  }
}

data "aws_lb_listener" "http" {
  count = var.enable_api_routes ? 1 : 0

  load_balancer_arn = data.aws_lb.ingress[0].arn
  port              = 80
}

locals {
  alb_listener_arn = var.enable_api_routes ? data.aws_lb_listener.http[0].arn : null

  integration_base = {
    type                   = "HTTP_PROXY"
    connection_type        = "VPC_LINK"
    vpc_link_key           = "alb"
    method                 = "ANY"
    payload_format_version = "1.0"
    uri                    = local.alb_listener_arn
  }

  public_integration = merge(local.integration_base, {
    request_parameters = {
      "remove:header.X-User-Id"           = ""
      "remove:header.X-User-Groups"       = ""
      "overwrite:header.X-Correlation-Id" = "$context.requestId"
    }
  })

  protected_integration = merge(local.integration_base, {
    request_parameters = {
      "overwrite:header.X-User-Id"        = "$context.authorizer.claims.sub"
      "overwrite:header.X-User-Groups"    = "$context.authorizer.claims.cognito:groups"
      "overwrite:header.X-Correlation-Id" = "$context.requestId"
    }
  })

  public_routes = [
    "GET /v1/items",
    "GET /v1/items/{slug}",
    "GET /v1/plants/{slug}",
  ]

  protected_routes = [
    "POST /v1/orders",
    "ANY /v1/journals",
    "ANY /v1/journals/{proxy+}",
    "ANY /v1/updates/{proxy+}",
    "ANY /v1/expert/tickets",
    "ANY /v1/expert/tickets/{proxy+}",
    "GET /v1/me",
    "GET /v1/me/entitlement",
    "ANY /v1/admin/users",
    "ANY /v1/admin/users/{proxy+}",
  ]

  api_routes = merge(
    { for route in local.public_routes : route => {
      integration = local.public_integration
    } if var.enable_api_routes },
    { for route in local.protected_routes : route => {
      authorization_type = "JWT"
      authorizer_key     = "cognito"
      integration        = local.protected_integration
    } if var.enable_api_routes },
  )
}

module "api" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "~> 6.1"

  name          = "growpath"
  description   = "GrowPath public API"
  protocol_type = "HTTP"

  create_domain_name    = false
  create_domain_records = false
  create_certificate    = false

  authorizers = {
    cognito = {
      authorizer_type  = "JWT"
      name             = "cognito"
      identity_sources = ["$request.header.Authorization"]

      jwt_configuration = {
        audience = [aws_cognito_user_pool_client.spa.id]
        issuer   = "https://cognito-idp.${var.region}.amazonaws.com/${aws_cognito_user_pool.this.id}"
      }
    }
  }

  vpc_links = {
    alb = {
      name               = "growpath"
      subnet_ids         = module.vpc.private_subnets
      security_group_ids = [module.vpc_link_sg.id]
    }
  }

  stage_default_route_settings = {
    detailed_metrics_enabled = false
    throttling_burst_limit   = var.api_throttling_burst_limit
    throttling_rate_limit    = var.api_throttling_rate_limit
  }

  stage_access_log_settings = {
    create_log_group            = true
    log_group_retention_in_days = 14
  }

  routes = local.api_routes
}
