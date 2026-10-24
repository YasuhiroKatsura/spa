# リソース起動/停止設定
variable "resource_flags" {
  type = object({
    api_tasks_enabled     = bool # ECS Service / Taskを作成・削除する（RDS有効時）
    api_stack_enabled     = bool # API Gateway、VPC Link、API用ALBを作成・削除する（ECS Serviceは維持）
    frontend_edge_enabled = bool # Frontend ALB、S3 VPC Endpointを作成・削除する
    s3_enabled            = bool # Frontend S3 Bucketを作成・削除する
    rds_enabled           = bool # Aurora cluster、instance、DB subnet group(, 付随してECS Service, Taskも)を作成・削除する
  })

  validation { # frontend_edge_enabledをtrueにする場合はs3_enabledもtrueとする必要がある
    condition     = var.resource_flags.s3_enabled || !var.resource_flags.frontend_edge_enabled
    error_message = "frontend_edge_enabled requires s3_enabled because the frontend edge serves content from the S3 bucket."
  }
}

# S3設定
variable "frontend_s3_conf" {
  type = object({
    bucket_policy_file = string
  })
}

# ECS設定 
variable "api_ecs_conf" {
  type = map(object({
    name               = string
    task_cpu           = number
    task_memory        = number
    desired_count      = number
    container_def_file = string
  }))
}

# RDS設定
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

# Cognito設定
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

# Cognitoシークレット設定（コード内には設定しない）
variable "entra_client_secret" {
  description = "Microsoft Entra ID app registration client secret. Set as an HCP Terraform sensitive variable."
  type        = string
  sensitive   = true
}
