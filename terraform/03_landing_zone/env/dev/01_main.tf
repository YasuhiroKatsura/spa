# -----実行環境-----
terraform {
  cloud {
    organization = "okamura"
    workspaces {
      name = "03_landing_zone"
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

variable "vpc" {
  type = map(string)
  default = {
    cidr_block = "10.0.0.0/16"
  }
}

variable "public_subnets" {
  type = map(string)
  default = {
    "a" = "10.0.0.0/24"
    "c" = "10.0.1.0/24"
  }
}

variable "private_subnets" {
  type = map(string)
  default = {
    "a" = "10.0.2.0/24"
    "c" = "10.0.3.0/24"
    "d" = "10.0.4.0/24" # Fargate用
  }
}

# -----Provider定義-----
provider "aws" {
  region = var.common.region
}

# -----module呼び出し-----
module "base_network_spa" {
  source = "../../modules/base_network"
  common = var.common
  vpc = var.vpc
  public_subnets = var.public_subnets
  private_subnets = var.private_subnets
}

# -----Output定義-----
output "ids" {
  value = module.base_network_spa.ids
}