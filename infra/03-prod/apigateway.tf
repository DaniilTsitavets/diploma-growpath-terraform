# The REST API is used instead of the HTTP API because only it can map the colon claim `cognito:groups`
# to a header. terraform-aws-modules has no REST API module (apigateway-v2 covers HTTP and WebSocket).
data "aws_lb" "ingress" {
  count = var.enable_api_routes ? 1 : 0

  tags = {
    "ingress-name" = "growpath"
  }
}

resource "aws_apigatewayv2_vpc_link" "alb" {
  name               = "growpath"
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [module.vpc_link_sg.id]
}

moved {
  from = module.api.aws_apigatewayv2_vpc_link.this["alb"]
  to   = aws_apigatewayv2_vpc_link.alb
}

locals {
  api_stage_name = "prod"

  alb_arn = var.enable_api_routes ? data.aws_lb.ingress[0].arn : ""
  alb_dns = var.enable_api_routes ? data.aws_lb.ingress[0].dns_name : ""

  # Without a signed-in user the identity headers are not mapped, so a client-sent X-User-Id passes through.
  public_routes = {
    "/v1/items"         = ["get"]
    "/v1/items/{slug}"  = ["get"]
    "/v1/plants/{slug}" = ["get"]
  }

  # Internal entitlement paths (/v1/quotas/*, /v1/entitlements) are deliberately not exposed.
  protected_routes = {
    "/v1/orders"                  = ["post"]
    "/v1/journals"                = ["any"]
    "/v1/journals/{proxy+}"       = ["any"]
    "/v1/updates/{proxy+}"        = ["any"]
    "/v1/expert/tickets"          = ["any"]
    "/v1/expert/tickets/{proxy+}" = ["any"]
    "/v1/me"                      = ["get"]
    "/v1/me/entitlement"          = ["get"]
    "/v1/admin/users"             = ["any"]
    "/v1/admin/users/{proxy+}"    = ["any"]
  }

  correlation_header = {
    "integration.request.header.X-Correlation-Id" = "context.requestId"
  }

  identity_headers = merge(local.correlation_header, {
    "integration.request.header.X-User-Id"     = "context.authorizer.claims.sub"
    "integration.request.header.X-User-Groups" = "context.authorizer.claims['cognito:groups']"
  })

  route_definitions = merge(
    { for path, methods in local.public_routes : path => { methods = methods, protected = false } },
    { for path, methods in local.protected_routes : path => { methods = methods, protected = true } },
  )

  # `{proxy+}` becomes the path parameter `proxy`.
  route_params = {
    for path, _ in local.route_definitions :
    path => flatten(regexall("\\{([a-z]+)\\+?\\}", path))
  }

  operations = {
    for path, route in local.route_definitions : path => {
      for method in route.methods : (method == "any" ? "x-amazon-apigateway-any-method" : method) => merge(
        {
          responses = { "200" = { description = "Proxied response" } }
          "x-amazon-apigateway-integration" = {
            type                = "http_proxy"
            httpMethod          = method == "any" ? "ANY" : upper(method)
            uri                 = "http://${local.alb_dns}${replace(path, "+", "")}"
            connectionType      = "VPC_LINK"
            connectionId        = aws_apigatewayv2_vpc_link.alb.id
            integrationTarget   = local.alb_arn
            passthroughBehavior = "when_no_match"
            requestParameters = merge(
              route.protected ? local.identity_headers : local.correlation_header,
              { for p in local.route_params[path] : "integration.request.path.${p}" => "method.request.path.${p}" },
            )
          }
        },
        route.protected ? { security = [{ cognito = [] }] } : {},
        length(local.route_params[path]) > 0 ? {
          parameters = [for p in local.route_params[path] : { name = p, in = "path", required = true, schema = { type = "string" } }]
        } : {},
      )
    }
  }

  # Until the ALB exists the API only has a mock root, so CloudFront always has an origin.
  mock_paths = {
    "/" = {
      get = {
        responses = { "200" = { description = "Placeholder" } }
        "x-amazon-apigateway-integration" = {
          type                = "mock"
          passthroughBehavior = "when_no_match"
          requestTemplates    = { "application/json" = jsonencode({ statusCode = 200 }) }
          responses           = { default = { statusCode = "200" } }
        }
      }
    }
  }

  openapi_base = {
    openapi = "3.0.1"
    info    = { title = "growpath", version = "1.0" }
    components = {
      securitySchemes = {
        cognito = {
          type                           = "apiKey"
          name                           = "Authorization"
          in                             = "header"
          "x-amazon-apigateway-authtype" = "cognito_user_pools"
          "x-amazon-apigateway-authorizer" = {
            type         = "cognito_user_pools"
            providerARNs = [aws_cognito_user_pool.this.arn]
          }
        }
      }
    }
  }

  openapi_body = var.enable_api_routes ? jsonencode(merge(local.openapi_base, { paths = local.operations })) : jsonencode(merge(local.openapi_base, { paths = local.mock_paths }))
}

resource "aws_api_gateway_rest_api" "this" {
  name        = "growpath"
  description = "GrowPath public API"
  body        = local.openapi_body

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeployment = sha1(aws_api_gateway_rest_api.this.body)
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id
  stage_name    = local.api_stage_name
}

resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "*/*"

  settings {
    throttling_rate_limit  = var.api_throttling_rate_limit
    throttling_burst_limit = var.api_throttling_burst_limit
  }
}
