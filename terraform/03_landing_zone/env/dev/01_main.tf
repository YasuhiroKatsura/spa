# -----変数定義-----
variable "common" {
  type = map(string)
  default = {
    project_name = "spa"
    region  = "ap-northeast-1"
    tfc_organization = "okamura"
    tfc_workspace = "03_landing_zone"
  }
}

variable "vpc" {
  type = map(string)
  default = {
    name = "spa"
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

# 使ってない
variable "private_subnets" {
  type = map(string)
  default = {
    # "a" = "10.0.2.0/24"
    # "c" = "10.0.3.0/24"
  }
}

# -----実行環境-----
terraform {
  cloud {
    organization = var.common.tfc_organization
    workspaces {
      name = var.common.tfc_workspace
    }
  }
}

# -----Provider定義-----
provider "aws" {
  region = var.common.region
}

# -----module呼び出し-----
module "vpc_spa" {
  source = "../../modules/vpc"
  common = var.common
  vpc = var.vpc
  public_subnets = var.public_subnets
  private_subnets = var.private_subnets
}

# -----output定義-----
# output "vpc_id" {
#   value       = module.vpc_spa.vpc_id
# }

# output "public_subnet_ids" {
#   value       = module.vpc_spa.public_subnet_ids
# }

# output "private_subnet_ids" {
#   value       = module.vpc_spa.private_subnet_ids
# }

output "ids" {
  value = module.vpc_spa.ids
}