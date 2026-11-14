# リソース起動/停止設定
variable "resource_flags" {
  type = object({
    api_tasks_enabled     = bool # ECS Service / Taskを作成・削除する（RDS有効時）
    api_stack_enabled     = bool # JWT認証付きAPI Gateway、VPC Link、API用ALBを作成・削除する（ECS Serviceは維持）
    frontend_edge_enabled = bool # Frontend ALB、S3 VPC Endpointを作成・削除する
    s3_enabled            = bool # Frontend S3 Bucketを作成・削除する
    rds_enabled           = bool # Aurora cluster、instance、DB subnet group(, 付随してECS Service, Taskも)を作成・削除する
  })

  validation { # frontend_edge_enabledをtrueにする場合はs3_enabledもtrueとする必要がある
    condition     = var.resource_flags.s3_enabled || !var.resource_flags.frontend_edge_enabled
    error_message = "frontend_edge_enabled requires s3_enabled because the frontend edge serves content from the S3 bucket."
  }

  validation {
    condition     = !var.resource_flags.api_stack_enabled || var.resource_flags.frontend_edge_enabled
    error_message = "api_stack_enabled requires frontend_edge_enabled so the API can configure CORS for the SPA origin."
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

# Microsoft Entra ID API registration settings
variable "auth_entra_conf" {
  type = object({
    tenant_id    = string
    api_audience = string
    api_scope    = string
  })

  validation {
    condition = !var.resource_flags.api_stack_enabled || (
      trimspace(var.auth_entra_conf.api_audience) != "" &&
      trimspace(var.auth_entra_conf.api_scope) != ""
    )
    error_message = "When api_stack_enabled is true, auth_entra_conf.api_audience and api_scope must be configured."
  }
}
