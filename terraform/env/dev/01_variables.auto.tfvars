common = {
  project_name = "spa"
  region       = "ap-northeast-1"
}

vpc_conf = {
  vpc = {
    cidr_block = "10.0.0.0/16"
  }
  public_subnets = {
    a = { cidr_block = "10.0.0.0/24" }
    c = { cidr_block = "10.0.1.0/24" }
  }
  private_subnets = {
    alb_a    = { cidr_block = "10.0.2.0/24" }
    alb_c    = { cidr_block = "10.0.3.0/24" }
    ecs_a    = { cidr_block = "10.0.4.0/24" }
    aurora_a = { cidr_block = "10.0.5.0/24" }
    aurora_c = { cidr_block = "10.0.6.0/24" }
  }
}

sg_conf = {
  api_tasks = {
    name        = "spa-sg-on-ecs-service4api" # xxx
    description = "Security group for the API ECS service"
    ingress_rules = {
      api_tasks_from_alb = {
        description                   = "Allow API load balancer traffic to ECS tasks"
        referenced_security_group_key = "api_alb"
        from_port                     = 80
        to_port                       = 80
        ip_protocol                   = "tcp"
      }
    }
    egress_rules = {
      api_tasks_all = {
        description = "Allow all outbound traffic"
        cidr_ipv4   = "0.0.0.0/0"
        ip_protocol = "-1"
      }
    }
  }
  api_alb = {
    name        = "spa-sg-on-alb-to-ecs4api"
    description = "Security group for the private API load balancer"
    ingress_rules = {
      api_alb_from_vpc_link = {
        description                   = "Allow API Gateway VPC Link traffic"
        referenced_security_group_key = "api_gateway_vpc_link"
        from_port                     = 80
        to_port                       = 80
        ip_protocol                   = "tcp"
      }
    }
    egress_rules = {
      api_alb_all = {
        description = "Allow all outbound traffic"
        cidr_ipv4   = "0.0.0.0/0"
        ip_protocol = "-1"
      }
    }
  }
  api_gateway_vpc_link = {
    name        = "spa-sg-on-vpc-link"
    description = "Security group for the API Gateway VPC Link"
    egress_rules = {
      api_gateway_to_alb = {
        description                   = "Allow API Gateway VPC Link traffic to the API load balancer"
        referenced_security_group_key = "api_alb"
        from_port                     = 80
        to_port                       = 80
        ip_protocol                   = "tcp"
      }
    }
  }
  database = {
    name        = "spa-sg-on-rds-aurora"
    description = "Security group for Aurora PostgreSQL"
    ingress_rules = {
      database_from_api = {
        description                   = "Allow PostgreSQL connections from the API tasks"
        referenced_security_group_key = "api_tasks"
        from_port                     = 5432
        to_port                       = 5432
        ip_protocol                   = "tcp"
      }
    }
    egress_rules = {
      database_all = {
        description = "Allow all outbound traffic"
        cidr_ipv4   = "0.0.0.0/0"
        ip_protocol = "-1"
      }
    }
  }
  frontend_alb = {
    name        = "spa-sg-on-alb-to-s34front"
    description = "Security group for the public frontend load balancer"
    ingress_rules = {
      frontend_alb_http = {
        description = "Allow public HTTP traffic"
        cidr_ipv4   = "0.0.0.0/0"
        from_port   = 80
        to_port     = 80
        ip_protocol = "tcp"
      }
    }
    egress_rules = {
      frontend_alb_all = {
        description = "Allow all outbound traffic"
        cidr_ipv4   = "0.0.0.0/0"
        ip_protocol = "-1"
      }
    }
  }
  frontend_endpoint = {
    name        = "spa-sg-on-vpcendpt-to-s34front"
    description = "Security group for the frontend S3 VPC endpoint"
    ingress_rules = {
      frontend_endpoint_from_alb = {
        description                   = "Allow HTTPS from the frontend load balancer"
        referenced_security_group_key = "frontend_alb"
        from_port                     = 443
        to_port                       = 443
        ip_protocol                   = "tcp"
      }
    }
    egress_rules = {
      frontend_endpoint_all = {
        description = "Allow all outbound traffic"
        cidr_ipv4   = "0.0.0.0/0"
        ip_protocol = "-1"
      }
    }
  }
}

iam_conf = {
  roles = {
    task_execution = {
      name                = "spa-ecs-task-execution-role-4api"
      description         = "ECS AgentがTask実行するための権限"
      assume_role_service = "ecs-tasks.amazonaws.com"
    }
    task = {
      name                    = "spa-ecs-task-role-4api"
      description             = "ECS TaskがAWSリソースにアクセスするための権限"
      assume_role_policy_file = "policy_connect_ssm.json"
      assume_role_service     = "ecs-tasks.amazonaws.com"
    }
  }

  inline_policies = {
    task_ssm_connection = { # ECS TaskにSSMのSendCommandを許可するポリシーを付与
      name               = "spa-ecs-task-role-execute-command-policy-4api"
      role_key           = "task"
      inline_policy_file = "policy_connect_ssm.json"
    }
  }

  managed_policy_attachments = {
    task_execution = {
      role_key   = "task_execution"
      policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
    }
    task_ssm = {
      role_key   = "task"
      policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }
}

task_conf = {
  api = {
    task_cpu           = 256
    task_memory        = 512
    desired_count      = 1
    container_def_file = "ecs_task4api.json"
    container_conf = {
      name      = "spa-ecs-container-4api"
      image_tag = "alpine"
    }
  }
}

database_conf = {
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

cognito_conf = {
  spa = {
    domain_prefix = "spa-auth"
    callback_urls = ["http://localhost:8080/"]
    logout_urls   = ["http://localhost:8080/"]
  }
}
