output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution."
  value       = module.cdn.cloudfront_distribution_id
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name behind the apex record."
  value       = module.cdn.cloudfront_distribution_domain_name
}

output "csp_origins" {
  description = "Origins the frontend build must allow in its CSP."
  value = {
    cognito = local.cognito_origin
    photos  = local.photos_origin
  }
}
