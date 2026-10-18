
variable "frontend_s3_conf" {
  type = object({
    bucket_policy_file = string
  })
}

variable "api_ecs_conf" {
  type = map(object({
    name = string
    task_cpu           = number
    task_memory        = number
    desired_count      = number
    container_def_file = string
  }))
}

# variable "api_apigw_conf" {
#   type = object({
#   })
# }

variable "database_rds_conf" {
  type = object({
    engine_version               = string
    instance_class               = string
    instance_count               = number
    backup_retention_days        = number
    deletion_protection          = bool
    skip_final_snapshot          = bool
    performance_insights_enabled = bool
  })
}

variable "auth_cognito_conf" {
  type = object({
    entra_tenant_id          = string # Microsoft Entra ID tenant ID used by the OIDC provider
    entra_client_id          = string # Microsoft Entra ID app registration client ID
    entra_oidc_authorize_url = string # Microsoft Entra ID OIDC authorization endpoint
    entra_oidc_issuer_url    = string # Microsoft Entra ID OIDC issuer URL
    entra_oidc_jwks_url      = string # Microsoft Entra ID OIDC JWKS endpoint
    entra_oidc_token_url     = string # Microsoft Entra ID OIDC token endpoint
    entra_oidc_userinfo_url  = string # Microsoft Entra ID OIDC userinfo endpoint
  })
}

variable "entra_client_secret" {
  description = "Microsoft Entra ID app registration client secret. Set as an HCP Terraform sensitive variable."
  type        = string
  sensitive   = true
}
