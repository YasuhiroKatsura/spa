module "vpc" { #vpc設定
  source   = "../../modules/vpc"
  common   = var.common
  vpc_conf = var.vpc_conf
}

module "sg" { # Security Group設定
  source  = "../../modules/sg"
  vpc_id  = module.vpc.vpc.id
  common  = var.common
  sg_conf = var.sg_conf
}

module "iam" { # IAM設定
  source   = "../../modules/iam"
  common   = var.common
  iam_conf = var.iam_conf
}

module "self_signed_cert" {
  count  = var.resource_flags.frontend_edge_enabled ? 1 : 0
  source = "../../modules/self_signed_cert"

  domain_name = var.self_signed_cert_conf.domain_name
}
