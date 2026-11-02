terraform { # HCP Terraform設定
  required_version = "~> 1.16.0"

  required_providers {
    # AWSプロバイダ
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.49.0"
    }
    # SSL証明書、証明書署名リクエスト（CSR）を生成・管理するためのプロバイダ
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.1.0"
    }
  }

  cloud {
    organization = "okamura"
    workspaces {
      name = "dev"
    }
  }
}

provider "aws" { # provider設定
  region = var.common.region

  default_tags {
    tags = {
      ProjectName = var.common.project_name
    }
  }
}
