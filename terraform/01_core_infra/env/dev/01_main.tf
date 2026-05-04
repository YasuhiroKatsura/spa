# -----実行環境-----
terraform {
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
  backend = "local"

  config = {
    path = "../../../03_landing_zone/env/dev/terraform.tfstate"
  }
}
