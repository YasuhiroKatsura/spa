terraform {
  required_version = ">= 1.14.0" # terraformバージョンの指定
  required_providers {
    aws = {
      source = "hashicorp/aws" # AWS Providerのバージョン指定
      version = ">= 6.33.0"
    }
  }
}

provider "aws" {
  region = var.region # AWS Providerのリージョン設定
}

# SPA用S3の定義
module "spa_s3" {
  source      = "./modules/storage/s3"
  bucket_name = "spa-y-okamura-dev-2026"
}

module "spa_vpc" {
  source      = "./modules/network/vpc"
  vpc_name = "spa-vpc"
  vpc_cidr = "10.0.0.0/16"
}

module "igw" {
  source   = "./modules/network/internet_gateway"
  vpc_id   = module.spa_vpc.vpc_id # ここでVPCモジュールの出力を参照
  igw_name = "spa-igw"
}

# XXX subnetはmap(object)にしたほうがいい？
module "alb_subnet-1a" {
  source      = "./modules/network/subnet"
  vpc_id      = module.spa_vpc.vpc_id # VPC IDを参照
  igw_id      = module.igw.igw_id   # IGW IDを参照
  subnet_cidr = "10.0.1.0/24"
  az          = "ap-northeast-1a"
  subnet_name = "spa-public-subnet-1a"
}

module "alb_subnet-1c" {
  source      = "./modules/network/subnet"
  vpc_id      = module.spa_vpc.vpc_id # VPC IDを参照
  igw_id      = module.igw.igw_id   # IGW IDを参照
  subnet_cidr = "10.0.2.0/24"
  az          = "ap-northeast-1c"
  subnet_name = "spa-public-subnet-1c"
}

module "alb_sg" {
  source = "./modules/security/security_group"
  vpc_id = module.spa_vpc.vpc_id # VPC IDを参照
  sg_name = "dev-alb-sg"
}

module "alb" {
  source = "./modules/load_balancer/alb"
  alb_name = "spa-alb"
  is_internal = false
  security_groups = [module.alb_sg.sg_id]
  subnet_ids = [module.alb_subnet-1a.subnet_id, module.alb_subnet-1c.subnet_id]
  http_listener_port = "80"

  # モジュールに複数のリスナールールを渡す
  listener_rules = {
    "s3_dir1_redirect" = {
      priority = 10
      action = {
        type = "redirect"
        redirect = {
          host        = "${module.spa_s3.bucket_id}.s3-website-ap-northeast-1.amazonaws.com"
          path        = "/dir1/#{path}"
          port        = "80"
          protocol    = "HTTP"
          status_code = "HTTP_301"
        }
      }
      condition = {
        path_pattern = ["/dir1/*"]
      }
    },
    "s3_dir2_redirect" = {
      priority = 20
      action = {
        type = "redirect"
        redirect = {
          host        = "${module.spa_s3.bucket_id}.s3-website-ap-northeast-1.amazonaws.com"
          path        = "/dir2/#{path}"
          port        = "80"
          protocol    = "HTTP"
          status_code = "HTTP_301"
        }
      }
      condition = {
        path_pattern = ["/dir2/*"]
      }
    }
  }
}