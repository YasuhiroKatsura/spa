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

provider "aws" {
  region = var.common.region
}
