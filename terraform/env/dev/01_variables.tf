variable "common" {
  type = object({
    project_name = string
    region       = string
  })
}

variable "vpc_conf" {
  type = object({
    vpc = object({
      cidr_block = string
    })
    public_subnets = map(object({
      cidr_block = string
    }))
    private_subnets = map(object({
      cidr_block = string
    }))
  })
}

variable "sg_conf" {
  type = map(object({
    name        = string
    description = string
    ingress_rules = optional(map(object({
      description                   = string
      ip_protocol                   = string
      from_port                     = optional(number)
      to_port                       = optional(number)
      cidr_ipv4                     = optional(string) # SGで制御する場合はnullに設定
      referenced_security_group_key = optional(string) # CIDRで制御する場合はnullに設定
    })), {})
    egress_rules = optional(map(object({
      description                   = string
      ip_protocol                   = string
      from_port                     = optional(number)
      to_port                       = optional(number)
      cidr_ipv4                     = optional(string) # SGで制御する場合はnullに設定
      referenced_security_group_key = optional(string) # CIDRで制御する場合はnullに設定
    })), {})
  }))
}

variable "iam_conf" {
  type = object({
    roles = map(object({ # IAM Roleの定義
      name                = string
      description         = string
      assume_role_service = string # IAM Roleを引き受けるサービスのARN
    }))

    inline_policies = map(object({ # インラインポリシーの定義
      name               = string
      role_key           = string # Policyの埋め込み対象となるIAM Roleのキー
      inline_policy_file = string
    }))

    # custom_policies = map(object({ # カスタマー管理ポリシーの定義
    #   name        = string
    #   policy_file = string
    # }))

    managed_policy_attachments = map(object({ # AWS管理ポリシー/カスタマー管理ポリシーの紐づけ
      role_key   = string
      policy_arn = string
    }))
  })
}

variable "task_conf" {
  type = map(object({
    task_cpu           = number
    task_memory        = number
    desired_count      = number
    container_def_file = string
    container_conf     = map(string)
  }))
}

variable "database_conf" {
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

variable "apigw_conf" {
  type = object({
    stage       = string
    auto_deploy = bool
  })
}

variable "cognito_conf" {
  type = map(object({
    domain_prefix = string
    callback_urls = list(string)
    logout_urls   = list(string)
  }))
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
