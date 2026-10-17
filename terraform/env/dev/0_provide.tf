terraform {
  required_version = "~> 1.15.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.49.0"
    }
  }

  cloud {
    organization = "okamura"
    workspaces {
      name = "spa-infra-dev"
    }
  }
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

locals {
  common = {
    project_name = "spa"
    region       = "ap-northeast-1"
  }

  network_conf = {
    vpc = {
      cidr_block = "10.0.0.0/16"
    }
    public_subnets = {
      a = { cidr_block = "10.0.0.0/24" }
      c = { cidr_block = "10.0.1.0/24" }
    }
    private_subnets = {
      alb_a    = { cidr_block = "10.0.2.0/24" }
      alb_c    = { cidr_block = "10.0.3.0/24" }
      ecs_a    = { cidr_block = "10.0.4.0/24" }
      aurora_a = { cidr_block = "10.0.5.0/24" }
      aurora_c = { cidr_block = "10.0.6.0/24" }
    }
  }

  container_conf = {
    task_cpu      = 256
    task_memory   = 512
    image_tag     = "alpine"
    desired_count = 1
  }

  db_conf = {
    engine_version               = "17.7"
    instance_class               = "db.t3.micro"
    instance_count               = 1
    backup_retention_days        = 1
    deletion_protection          = false
    skip_final_snapshot          = true
    performance_insights_enabled = false
  }

  apigw_conf = {
    stage       = "dev"
    auto_deploy = true
  }

  cognito_domain_prefix = "spa-auth"
  cognito_callback_urls = ["http://localhost:8080/"]
  cognito_logout_urls   = ["http://localhost:8080/"]
}

provider "aws" {
  region = local.common.region

  default_tags {
    tags = {
      ProjectName = local.common.project_name
    }
  }
}
