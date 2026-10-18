resource "aws_lb" "api" {
  name               = "${var.common.project_name}-alb-to-ecs4api"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [module.sg.id["api_alb"]]
  subnets = [
    module.vpc.subnet.private_subnet_ids_by_name.alb_a,
    module.vpc.subnet.private_subnet_ids_by_name.alb_c,
  ]

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "api" {
  name        = "${var.common.project_name}-alb-tg-4api"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc.id
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

resource "aws_lb_listener" "api" {
  load_balancer_arn = aws_lb.api.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

resource "aws_ecs_cluster" "api" {
  name = "${var.common.project_name}-ecs-cluster4api"
}

resource "aws_ecs_task_definition" "api" {
  family                   = "${var.common.project_name}-ecs-task4api"
  cpu                      = var.task_conf.api.task_cpu
  memory                   = var.task_conf.api.task_memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = module.iam.arn["task_execution"] # ECS AgentがTask実行するための権限
  task_role_arn            = module.iam.arn["task"]           # ECS TaskがAWSリソースにアクセスするための権限

  container_definitions = templatefile(
    "${path.root}/templates/${each.value.container_def_file}",
    {
      container_conf = var.task_conf.api.container_conf
      db_host       = aws_rds_cluster.aurora.endpoint
      db_port       = tostring(aws_rds_cluster.aurora.port)
      db_name       = aws_rds_cluster.aurora.database_name
      db_user       = aws_rds_cluster.aurora.master_username
      db_secret_arn = aws_rds_cluster.aurora.master_user_secret[0].secret_arn
    }
  )

  runtime_platform {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }
}

resource "aws_ecs_service" "api" {
  name                   = "${var.common.project_name}-ecs-service4api"
  cluster                = aws_ecs_cluster.api.id
  task_definition        = aws_ecs_task_definition.task["api"].arn
  desired_count          = var.task_conf.api.desired_count
  enable_execute_command = true

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 100
  }

  network_configuration {
    subnets          = [module.vpc.subnet.private_subnet_ids_by_name.ecs_a]
    security_groups  = [module.sg.id["api_tasks"]]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = var.task_conf.api.container_conf.name
    container_port   = 80
  }

  depends_on = [aws_lb_listener.api]
}
