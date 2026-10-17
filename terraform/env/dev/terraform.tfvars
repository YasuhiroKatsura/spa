common = {
  project_name = "spa"
  region       = "ap-northeast-1"
}

network_conf = {
  vpc = {
    cidr_block = "10.0.0.0/16"
  }

  public_subnets = {
    a = {
      cidr_block = "10.0.0.0/24"
    }
    c = {
      cidr_block = "10.0.1.0/24"
    }
  }

  private_subnets = {
    alb_a = {
      cidr_block = "10.0.2.0/24"
    }
    alb_c = {
      cidr_block = "10.0.3.0/24"
    }
    ecs_a = {
      cidr_block = "10.0.4.0/24"
    }
    aurora_a = {
      cidr_block = "10.0.5.0/24"
    }
    aurora_c = {
      cidr_block = "10.0.6.0/24"
    }
  }
}

container_conf = {
  task_cpu      = 256
  task_memory   = 512
  image_tag     = "alpine"
  desired_count = 1
}

db_conf = {
  engine_version               = "17.7"
  instance_class               = "db.t3.micro"
  instance_count               = 1
  backup_retention_days        = 1
  deletion_protection          = false
  skip_final_snapshot          = true
  performance_insights_enabled = false
}

apigw_conf = {
  stage       = "dev"
  auto_deploy = true
}
