variable "common" {
  type = object({
    project_name = string
    region       = string
  })
}

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
  default     = "spa-auth"
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
