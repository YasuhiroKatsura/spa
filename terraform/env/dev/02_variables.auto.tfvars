
resource_flags = {
  api_tasks_enabled     = false
  api_stack_enabled     = false
  frontend_edge_enabled = false
  s3_enabled            = false
  rds_enabled           = false
}

frontend_s3_conf = {
  bucket_policy_file = "bucket_policy_frontend.json"
}

api_ecs_conf = {
  main = {
    name               = "main"
    task_cpu           = 256
    task_memory        = 512
    desired_count      = 1
    container_def_file = "container_def_main.json"
  }
}

database_rds_conf = {
  engine_version               = "17.7"
  instance_class               = "db.t3.medium"
  instance_count               = 1
  backup_retention_days        = 1
  deletion_protection          = false
  skip_final_snapshot          = true
  performance_insights_enabled = false
}

auth_cognito_conf = {
  entra_tenant_id          = "48d5d751-0dc5-4a60-8a05-d9b5e8e76d72"
  entra_client_id          = "5016b4cb-4b4e-4e51-b56f-46a1b12de113"
  entra_oidc_authorize_url = "https://login.microsoftonline.com/48d5d751-0dc5-4a60-8a05-d9b5e8e76d72/oauth2/v2.0/authorize"
  entra_oidc_issuer_url    = "https://login.microsoftonline.com/48d5d751-0dc5-4a60-8a05-d9b5e8e76d72/v2.0"
  entra_oidc_jwks_url      = "https://login.microsoftonline.com/48d5d751-0dc5-4a60-8a05-d9b5e8e76d72/discovery/v2.0/keys"
  entra_oidc_token_url     = "https://login.microsoftonline.com/48d5d751-0dc5-4a60-8a05-d9b5e8e76d72/oauth2/v2.0/token"
  entra_oidc_userinfo_url  = "https://login.microsoftonline.com/48d5d751-0dc5-4a60-8a05-d9b5e8e76d72/oauth2/v2.0/userinfo"
}
