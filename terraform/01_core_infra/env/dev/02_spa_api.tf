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
  execution_role_arn       = aws_iam_role.role_ecs_task_execution.arn
  task_role_arn            = aws_iam_role.role_ecs_task.arn
  container_definitions = templatefile(
    "./03_ecs_task4api.json",
    {
      name = "${var.common.project_name}-ecs-container-4api"
      image_tag = "${var.spa_api.image_tag}"
      db_host = aws_rds_cluster.aurora_cluster.endpoint
      db_port = aws_rds_cluster.aurora_cluster.port
      db_name = aws_rds_cluster.aurora_cluster.database_name
      db_user = aws_rds_cluster.aurora_cluster.master_username
      db_secret_arn = aws_rds_cluster.aurora_cluster.master_user_secret[0].secret_arn
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
  enable_execute_command = true # SSMからのコンテナ接続を許可

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 100
  }

  network_configuration {
    subnets          = [
      data.terraform_remote_state.landing_zone.outputs.ids.private_subnet_ids[2]
    ]
    security_groups  = [aws_security_group.sg_on_ecs_service4api.id]
    assign_public_ip = "false"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.alb_tg_4api.arn
    container_name   = "${var.common.project_name}-ecs-container-4api"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.alb_to_ecs4api]
}

# -----IAM Role (ECS Task Execution Role)-----
resource "aws_iam_role" "role_ecs_task_execution" {
  name = "${var.common.project_name}-ecs-task-execution-role-4api"

  assume_role_policy = templatefile(
    "./03_trust_policy.json",
    {
      service = "ecs-tasks.amazonaws.com"
    }
  )
}

resource "aws_iam_role_policy_attachment" "role_ecs_task_execution_execution_policy" {
  role       = aws_iam_role.role_ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# -----IAM Role (ECS Task Role)-----
resource "aws_iam_role" "role_ecs_task" {
  name = "${var.common.project_name}-ecs-task-role-4api"

  assume_role_policy = templatefile(
    "./03_trust_policy.json",
    {
      service = "ecs-tasks.amazonaws.com"
    }
  )
}

resource "aws_iam_role_policy_attachment" "role_ecs_task_ssm_policy" {
  role       = aws_iam_role.role_ecs_task.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "policy_connect_ssm_for_ecs_task" {
  name = "${var.common.project_name}-ecs-task-role-execute-command-policy-4api"
  role = aws_iam_role.role_ecs_task.id

  policy = templatefile("./03_policy_connect_ssm.json", {})
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
