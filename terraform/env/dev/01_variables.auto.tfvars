common = { # プロジェクト共通の設定
  project_name = "spa"
  env          = "dev"
  region       = "ap-northeast-1"
}

vpc_conf = { # VPC設定
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

sg_conf = { # Security Group設定
  ecs_service_main = {
    name        = "ecs-service-main"
    description = "Security group for the API ECS service"
    ingress_rules = {
      ingress_from_alb_for_ecs = {
        description                   = "Allow API load balancer traffic to ECS tasks"
        from_port                     = 80
        to_port                       = 80
        ip_protocol                   = "tcp"
        referenced_security_group_key = "api_alb"
      }
    }
    egress_rules = {
      egress_to_all = {
        description = "Allow all outbound traffic"
        ip_protocol = "-1"
        cidr_ipv4   = ["0.0.0.0/0"]
      }
    }
  }
  api_alb = {
    name        = "api-alb"
    description = "Security group for the private API load balancer"
    ingress_rules = {
      ingress_from_vpc_link_for_apigw = {
        description                   = "Allow API Gateway VPC Link traffic"
        from_port                     = 80
        to_port                       = 80
        ip_protocol                   = "tcp"
        referenced_security_group_key = "vpc_link_for_apigw"
      }
    }
    egress_rules = {
      egress_to_all = {
        description = "Allow all outbound traffic"
        ip_protocol = "-1"
        cidr_ipv4   = ["0.0.0.0/0"]
      }
    }
  }
  vpc_link_for_apigw = {
    name        = "vpc-link-for-apigw"
    description = "Security group for the API Gateway VPC Link"
    egress_rules = {
      egress_to_alb_for_ecs = {
        description                   = "Allow API Gateway VPC Link traffic to the API load balancer"
        from_port                     = 80
        to_port                       = 80
        ip_protocol                   = "tcp"
        referenced_security_group_key = "api_alb"
      }
    }
  }
  rds = {
    name        = "rds"
    description = "Security group for Aurora PostgreSQL"
    ingress_rules = {
      ingress_from_ecs_service_main = {
        description                   = "Allow PostgreSQL connections from the API tasks"
        from_port                     = 5432
        to_port                       = 5432
        ip_protocol                   = "tcp"
        referenced_security_group_key = "ecs_service_main"
      }
    }
    egress_rules = {
      egress_to_all = {
        description = "Allow all outbound traffic"
        ip_protocol = "-1"
        cidr_ipv4   = ["0.0.0.0/0"]
      }
    }
  }
  frontend_alb = {
    name        = "frontend-alb"
    description = "Security group for the public frontend load balancer"
    ingress_rules = {
      ingress_from_internet = {
        description = "Allow public HTTP traffic"
        cidr_ipv4   = ["0.0.0.0/0"]
        from_port   = 80
        to_port     = 80
        ip_protocol = "tcp"
      }
    }
    egress_rules = {
      egress_to_s3_endpoint = {
        description                   = "Allow HTTPS to the S3 VPC endpoint"
        referenced_security_group_key = "vpc_endpt_for_s3"
        from_port                     = 443
        to_port                       = 443
        ip_protocol                   = "tcp"
      }
    }
  }
  vpc_endpt_for_s3 = {
    name        = "vpc-endpt-for-s3"
    description = "Security group for the S3 VPC endpoint"
    ingress_rules = {
      ingress_from_frontend_alb = {
        description                   = "Allow HTTPS from the frontend load balancer"
        referenced_security_group_key = "frontend_alb"
        from_port                     = 443
        to_port                       = 443
        ip_protocol                   = "tcp"
      }
    }
    egress_rules = {
      egress_to_all = {
        description = "Allow all outbound traffic"
        cidr_ipv4   = ["0.0.0.0/0"]
        ip_protocol = "-1"
      }
    }
  }
}

iam_conf = { # IAM設定
  roles = {
    task_execution = {
      name                    = "ecs-task-execution"
      description             = "permission for ECS Agent to execute tasks"
      assume_role_policy_file = "trust_policy_task.json"
      assume_role_service     = "ecs-tasks.amazonaws.com"
    }
    task = {
      name                    = "ecs-task"
      description             = "permission for ECS Task to access AWS resources"
      assume_role_policy_file = "trust_policy_task.json"
      assume_role_service     = "ecs-tasks.amazonaws.com"
    }
  }

  inline_policies = {
    task_ssm_connection = { # ECS TaskにSSMのSendCommandを許可するポリシーを付与
      name               = "ecs-task-ssm-connection"
      role_key           = "task"
      inline_policy_file = "inline_policy_task_ssm_connection.json"
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
