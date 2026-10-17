# output "cognito_user_pool_id" {
# 	description = "Cognito User Pool ID for the SPA authentication flow."
# 	value       = aws_cognito_user_pool.spa.id
# }

# output "cognito_user_pool_client_id" {
# 	description = "Cognito User Pool app client ID for the SPA authentication flow."
# 	value       = aws_cognito_user_pool_client.spa.id
# }

# output "cognito_issuer_url" {
# 	description = "Cognito User Pool issuer URL for downstream JWT validation."
# 	value       = "https://cognito-idp.${var.common.region}.amazonaws.com/${aws_cognito_user_pool.spa.id}"
# }
