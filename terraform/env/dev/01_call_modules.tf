module "vpc" { #vpc設定
  source   = "../../modules/vpc"
  common   = var.common
  vpc_conf = var.vpc_conf
}

module "sg" { # Security Group設定
  source  = "../../modules/sg"
  vpc_id  = module.vpc.vpc.id
  common   = var.common
  sg_conf = var.sg_conf
}

module "iam" { # IAM設定
  source   = "../../modules/iam"
  common   = var.common
  iam_conf = var.iam_conf
}