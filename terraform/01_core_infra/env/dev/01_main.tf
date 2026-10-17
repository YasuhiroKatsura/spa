# -----実行環境-----
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
      name = "01_core_infra"
    }
  }
}

# -----変数定義-----
variable "common" {
  type = map(string)
  default = {
    project_name = "spa"
    region  = "ap-northeast-1"
  }
}

# -----Provider定義-----
provider "aws" {
  region = var.common.region
}

# -----tfstateの読み込み-----
data "terraform_remote_state" "landing_zone" {
  backend = "remote"

  config = {
    organization = "okamura" 

    workspaces = {
      name = "03_landing_zone" 
    }
  }
}
