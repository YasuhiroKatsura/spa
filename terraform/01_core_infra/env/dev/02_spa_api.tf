# -----変数定義-----
variable "spa_api" {
  type = map(string)
  default = {
    task_cpu = "256" # unit (1 vCPU = 1024 units)
    task_memory = "512" # MiB
    image_tag = "alpine" # テスト用
    desired_count = "1"
  }
}

# -----IAM Role (ECS Task Execution Role)-----
resource "aws_iam_role" "ecs_task_execution_role_4api" {
  name = "${var.common.project_name}-ecs-task-execution-role-4api"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_4api" {
  role       = aws_iam_role.ecs_task_execution_role_4api.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# -----IAM Role (ECS Task Role - for SSM)-----
resource "aws_iam_role" "ecs_task_role_4api" {
  name = "${var.common.project_name}-ecs-task-role-4api"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_ssm_policy_4api" {
  role       = aws_iam_role.ecs_task_role_4api.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "ecs_task_role_execute_command_policy_4api" {
  name = "${var.common.project_name}-ecs-task-role-execute-command-policy-4api"
  role = aws_iam_role.ecs_task_role_4api.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel", # SSMセッション用の制御チャネルを作成
          "ssmmessages:CreateDataChannel", # コマンド実行・ファイル転送用のデータチャネルを作成
          "ssmmessages:OpenControlChannel", # 既存の制御チャネルを開く（再接続時など）
          "ssmmessages:OpenDataChannel" # 既存のデータチャネルを開く（既存セッション利用）
        ]
        Resource = "*"
      },
    ]
  })
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# -----ALB-----
resource "aws_lb" "alb_to_ecs4api" {
  name               = "${var.common.project_name}-alb-to-ecs4api"
  internal           = "true" # プライベート
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_on_alb_to_ecs4api.id]
  subnets            = [
    data.terraform_remote_state.landing_zone.outputs.ids.private_subnet_ids[0],
    data.terraform_remote_state.landing_zone.outputs.ids.private_subnet_ids[1]
  ]

  enable_deletion_protection = "false" # 削除保護は無効（個人利用なので...）
}

resource "aws_lb_target_group" "alb_tg_4api" {
  name        = "${var.common.project_name}-alb-tg-4api"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.landing_zone.outputs.ids.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/"
    matcher             = "200"
  }
}

resource "aws_lb_listener" "alb_to_ecs4api" {
  load_balancer_arn = aws_lb.alb_to_ecs4api.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg_4api.arn
  }
}

# -----security group (ALB用)-----
resource "aws_security_group" "sg_on_alb_to_ecs4api" {
  name        = "${var.common.project_name}-sg-on-alb-to-ecs4api"
  vpc_id      = data.terraform_remote_state.landing_zone.outputs.ids.vpc_id
}

resource "aws_security_group_rule" "sgrule_ingress_on_alb_to_ecs4api" {
  security_group_id = aws_security_group.sg_on_alb_to_ecs4api.id
  type                     = "ingress"
  from_port                = "80"
  to_port                  = "80"
  protocol                 = "tcp"
  source_security_group_id        = aws_security_group.sg_on_vpclink_to_ecs4api.id
}

resource "aws_security_group_rule" "sgrule_egress_on_alb_to_ecs4api" {
  security_group_id = aws_security_group.sg_on_alb_to_ecs4api.id
  type                = "egress"
  from_port           = "0"
  to_port             = "0"
  protocol            = "-1"
  cidr_blocks         = ["0.0.0.0/0"]
}

# -----ECS on Fargate-----
resource "aws_ecs_cluster" "ecs_cluster4api" {
  name = "${var.common.project_name}-ecs-cluster4api"
}

resource "aws_ecs_task_definition" "ecs_task4api" {
  family                   = "${var.common.project_name}-ecs-task4api"
  cpu                      = "${var.spa_api.task_cpu}"
  memory                   = "${var.spa_api.task_memory}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role_4api.arn
  task_role_arn            = aws_iam_role.ecs_task_role_4api.arn
  container_definitions = templatefile(
    "./03_ecs_task4api.json",
    {
      name = "${var.common.project_name}-ecs-container-4api"
      image_tag = "${var.spa_api.image_tag}"
    }
  )

  runtime_platform {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }
}

resource "aws_ecs_service" "ecs_service4api" {
  name            = "${var.common.project_name}-ecs-service4api"
  cluster         = aws_ecs_cluster.ecs_cluster4api.id
  task_definition = aws_ecs_task_definition.ecs_task4api.arn
  desired_count   = "${var.spa_api.desired_count}"
  launch_type     = "FARGATE"
  enable_execute_command = true # SSMからのコンテナ接続を許可

  network_configuration {
    subnets          = [
      data.terraform_remote_state.landing_zone.outputs.ids.private_subnet_ids[2]
    ]
    security_groups  = [aws_security_group.sg_on_ecs_service4api.id]
    assign_public_ip = "false"
  }

  # ↓かみ砕く
  load_balancer {
    target_group_arn = aws_lb_target_group.alb_tg_4api.arn
    container_name   = "${var.common.project_name}-ecs-container-4api"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.alb_to_ecs4api]
}


# -----security group (ECS Service用)-----
resource "aws_security_group" "sg_on_ecs_service4api" {
  name        = "${var.common.project_name}-sg-on-ecs-service4api"
  vpc_id      = data.terraform_remote_state.landing_zone.outputs.ids.vpc_id
}

resource "aws_security_group_rule" "sgrule_ingress_on_ecs_service4api" {
  security_group_id = aws_security_group.sg_on_ecs_service4api.id
  type                     = "ingress"
  from_port                = "80"
  to_port                  = "80"
  protocol                 = "tcp"
  source_security_group_id        = aws_security_group.sg_on_alb_to_ecs4api.id
}

resource "aws_security_group_rule" "sgrule_egress_on_ecs_service4api" {
  security_group_id = aws_security_group.sg_on_ecs_service4api.id
  type                = "egress"
  from_port           = "0"
  to_port             = "0"
  protocol            = "-1"
  cidr_blocks         = ["0.0.0.0/0"]
}
