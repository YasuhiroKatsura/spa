terraform {
  required_version = "~> 1.16.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.49.0"
    }
  }

  cloud {
    organization = "okamura"
    workspaces {
      name = "dev"
    }
  }
}

provider "aws" {
  region = var.common.region

  default_tags {
    tags = {
      ProjectName = var.common.project_name
    }
  }
}
