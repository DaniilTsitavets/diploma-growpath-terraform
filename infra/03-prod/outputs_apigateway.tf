output "api_id" {
  description = "ID of the REST API."
  value       = aws_api_gateway_rest_api.this.id
}

output "api_endpoint" {
  description = "Invoke URL of the API stage that CloudFront uses as the API origin."
  value       = aws_api_gateway_stage.this.invoke_url
}

output "alb_security_group_id" {
  description = "Security group for the internal ALB, referenced by the Ingress annotation."
  value       = module.alb_sg.id
}
