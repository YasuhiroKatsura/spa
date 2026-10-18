module "vpc" {
  source   = "../../modules/vpc"
  common   = var.common
  vpc_conf = var.vpc_conf
}

module "sg" {
  source  = "../../modules/sg"
  vpc_id  = module.vpc.vpc.id
  sg_conf = var.sg_conf
}

module "iam" {
  source   = "../../modules/iam"
  iam_conf = var.iam_conf
}