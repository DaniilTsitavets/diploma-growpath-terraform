locals {
  photos_origin  = "https://${module.s3_photos.s3_bucket_id}.s3.${var.region}.amazonaws.com"
  cognito_origin = "https://cognito-idp.${var.region}.amazonaws.com"

  content_security_policy = join("; ", [
    "default-src 'none'",
    "script-src 'self'",
    "style-src 'self'",
    "img-src 'self' data: blob: ${local.photos_origin}",
    "font-src 'self'",
    "connect-src 'self' ${local.cognito_origin} ${local.photos_origin}",
    "manifest-src 'self'",
    "object-src 'none'",
    "base-uri 'none'",
    "form-action 'self'",
    "worker-src 'none'",
    "require-trusted-types-for 'script'",
    "frame-ancestors 'none'",
  ])
}

data "aws_iam_policy_document" "frontend_oac" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::growpath-prod-frontend-${local.bucket_suffix}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [module.cdn.cloudfront_distribution_arn]
    }
  }
}

data "aws_iam_policy_document" "media_oac" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::growpath-prod-media-${local.bucket_suffix}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [module.cdn.cloudfront_distribution_arn]
    }
  }
}

module "cdn" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "~> 6.8"

  comment             = "GrowPath"
  aliases             = [var.domain_name]
  default_root_object = "index.html"
  price_class         = "PriceClass_100"
  is_ipv6_enabled     = true

  viewer_certificate = {
    acm_certificate_arn = aws_acm_certificate_validation.this.certificate_arn
    ssl_support_method  = "sni-only"
  }

  origin = {
    frontend = {
      domain_name               = module.s3_frontend.s3_bucket_bucket_regional_domain_name
      origin_access_control_key = "s3"
    }
    media = {
      domain_name               = module.s3_media.s3_bucket_bucket_regional_domain_name
      origin_access_control_key = "s3"
    }
    api = {
      domain_name = "${aws_api_gateway_rest_api.this.id}.execute-api.${var.region}.amazonaws.com"
      origin_path = "/${local.api_stage_name}"
      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  response_headers_policies = {
    security = {
      security_headers_config = {
        content_security_policy = {
          content_security_policy = local.content_security_policy
          override                = true
        }
        content_type_options = {
          override = true
        }
        frame_options = {
          frame_option = "DENY"
          override     = true
        }
        referrer_policy = {
          referrer_policy = "strict-origin-when-cross-origin"
          override        = true
        }
        strict_transport_security = {
          access_control_max_age_sec = 31536000
          include_subdomains         = true
          override                   = true
        }
      }
      custom_headers_config = {
        items = [
          {
            header   = "Permissions-Policy"
            value    = "camera=(), microphone=(), geolocation=(), payment=(), usb=()"
            override = true
          },
          {
            header   = "Cross-Origin-Opener-Policy"
            value    = "same-origin"
            override = true
          },
        ]
      }
    }
  }

  cloudfront_functions = {
    spa = {
      publish = true
      runtime = "cloudfront-js-2.0"
      code    = <<-JS
        function handler(event) {
          var request = event.request;
          var last = request.uri.split('/').pop();
          if (last.indexOf('.') === -1) {
            request.uri = '/index.html';
          }
          return request;
        }
      JS
    }
    strip_media = {
      publish = true
      runtime = "cloudfront-js-2.0"
      code    = <<-JS
        function handler(event) {
          var request = event.request;
          request.uri = request.uri.replace(/^\/media/, '');
          return request;
        }
      JS
    }
  }

  default_cache_behavior = {
    target_origin_id            = "frontend"
    viewer_protocol_policy      = "redirect-to-https"
    cache_policy_name           = "Managed-CachingOptimized"
    response_headers_policy_key = "security"
    function_association = {
      viewer-request = { function_key = "spa" }
    }
  }

  ordered_cache_behavior = [
    {
      path_pattern               = "/v1/*"
      target_origin_id           = "api"
      viewer_protocol_policy     = "https-only"
      allowed_methods            = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods             = ["GET", "HEAD"]
      cache_policy_name          = "Managed-CachingDisabled"
      origin_request_policy_name = "Managed-AllViewerExceptHostHeader"
    },
    {
      path_pattern                = "/media/*"
      target_origin_id            = "media"
      viewer_protocol_policy      = "redirect-to-https"
      cache_policy_name           = "Managed-CachingOptimized"
      response_headers_policy_key = "security"
      function_association = {
        viewer-request = { function_key = "strip_media" }
      }
    },
  ]
}

resource "aws_route53_record" "apex" {
  provider = aws.dns

  for_each = toset(["A", "AAAA"])

  zone_id = local.zone_id
  name    = var.domain_name
  type    = each.key

  alias {
    name                   = module.cdn.cloudfront_distribution_domain_name
    zone_id                = module.cdn.cloudfront_distribution_hosted_zone_id
    evaluate_target_health = false
  }
}
