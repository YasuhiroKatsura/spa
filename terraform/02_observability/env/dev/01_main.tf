# -----実行環境-----
terraform {
  cloud {
    organization = "okamura"
    workspaces {
      name = "02_observability"
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
    # あなたのOrganization名
    organization = "okamura" 

    # 参照したい先のWorkspace名
    workspaces = {
      name = "03_landing_zone" 
    }
  }
}