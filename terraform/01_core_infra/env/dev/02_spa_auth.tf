variable "entra_tenant_id" {
	description = "Microsoft Entra ID tenant ID used by the OIDC provider."
	type        = string
}

variable "entra_oidc_issuer_url" {
	description = "Tenant-specific Microsoft Entra ID OIDC issuer URL."
	type        = string
}

variable "entra_oidc_authorize_url" {
	description = "Microsoft Entra ID OIDC authorization endpoint."
	type        = string
}

variable "entra_oidc_token_url" {
	description = "Microsoft Entra ID OIDC token endpoint."
	type        = string
}

variable "entra_oidc_jwks_url" {
	description = "Microsoft Entra ID OIDC JWKS endpoint."
	type        = string
}

variable "entra_oidc_userinfo_url" {
	description = "Microsoft Entra ID OIDC userinfo endpoint."
	type        = string
}

variable "entra_client_id" {
	description = "Microsoft Entra ID app registration client ID."
	type        = string
}

variable "entra_client_secret" {
	description = "Microsoft Entra ID app registration client secret. Set as an HCP Terraform sensitive variable."
	type        = string
	sensitive   = true
}

variable "cognito_domain_prefix" {
	description = "Globally unique prefix for the Cognito Hosted UI domain."
	type        = string
    default    = "spa-auth"
}

variable "cognito_callback_urls" {
	description = "SPA callback URLs registered on the Cognito app client."
	type        = list(string)
	default     = ["http://localhost:8080/"]
}

variable "cognito_logout_urls" {
	description = "SPA logout URLs registered on the Cognito app client."
	type        = list(string)
	default     = ["http://localhost:8080/"]
}

resource "aws_cognito_user_pool" "spa" {
	name = "${var.common.project_name}-user-pool"

	username_attributes      = ["email"]
	auto_verified_attributes = ["email"]

	account_recovery_setting {
		recovery_mechanism {
			name     = "verified_email"
			priority = 1
		}
	}
}

resource "aws_cognito_identity_provider" "entra" {
	user_pool_id  = aws_cognito_user_pool.spa.id
	provider_name = "EntraID"
	provider_type = "OIDC"

	provider_details = {
		client_id                 = var.entra_client_id
		client_secret             = var.entra_client_secret
		authorize_scopes          = "openid email profile"
		oidc_issuer               = var.entra_oidc_issuer_url
		authorize_url             = var.entra_oidc_authorize_url
		token_url                 = var.entra_oidc_token_url
		jwks_uri                  = var.entra_oidc_jwks_url
		attributes_url             = var.entra_oidc_userinfo_url
		attributes_request_method = "GET"
	}

	attribute_mapping = {
		email    = "email"
		name     = "name"
		username = "sub"
	}
}

resource "aws_cognito_user_pool_client" "spa" {
	name         = "${var.common.project_name}-spa-client"
	user_pool_id = aws_cognito_user_pool.spa.id

	generate_secret = false

	allowed_oauth_flows                  = ["code"]
	allowed_oauth_flows_user_pool_client = true
	allowed_oauth_scopes                 = ["openid", "email", "profile"]
	callback_urls                        = var.cognito_callback_urls
	logout_urls                          = var.cognito_logout_urls
	supported_identity_providers         = [aws_cognito_identity_provider.entra.provider_name]
}

resource "aws_cognito_user_pool_domain" "spa" {
	domain       = var.cognito_domain_prefix
	user_pool_id = aws_cognito_user_pool.spa.id
}

locals {
	cognito_hosted_ui_url = "https://${aws_cognito_user_pool_domain.spa.domain}.auth.${var.common.region}.amazoncognito.com"
}

output "cognito_user_pool_id" {
	description = "Cognito User Pool ID for the SPA authentication flow."
	value       = aws_cognito_user_pool.spa.id
}

output "cognito_user_pool_client_id" {
	description = "Cognito User Pool app client ID for the SPA authentication flow."
	value       = aws_cognito_user_pool_client.spa.id
}

output "cognito_issuer_url" {
	description = "Cognito User Pool issuer URL for downstream JWT validation."
	value       = "https://cognito-idp.${var.common.region}.amazonaws.com/${aws_cognito_user_pool.spa.id}"
}

output "cognito_hosted_ui_url" {
	description = "Cognito Hosted UI base URL."
	value       = local.cognito_hosted_ui_url
}

output "cognito_entra_idp_response_url" {
	description = "Redirect URI to register in the Microsoft Entra app registration."
	value       = "${local.cognito_hosted_ui_url}/oauth2/idpresponse"
}
