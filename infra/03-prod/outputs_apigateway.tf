output "api_id" {
  description = "ID of the HTTP API."
  value       = module.api.api_id
}

output "api_endpoint" {
  description = "Default execute-api endpoint that CloudFront uses as the API origin."
  value       = module.api.api_endpoint
}

output "alb_security_group_id" {
  description = "Security group for the internal ALB, referenced by the Ingress annotation."
  value       = module.alb_sg.id
}
