output "cognito_user_pool_id" {
  description = "ID of the Cognito user pool."
  value       = aws_cognito_user_pool.this.id
}

output "cognito_user_pool_arn" {
  description = "ARN of the Cognito user pool."
  value       = aws_cognito_user_pool.this.arn
}

output "cognito_spa_client_id" {
  description = "ID of the SPA app client."
  value       = aws_cognito_user_pool_client.spa.id
}

output "cognito_issuer" {
  description = "Issuer URL of the user pool tokens."
  value       = "https://cognito-idp.${var.region}.amazonaws.com/${aws_cognito_user_pool.this.id}"
}
