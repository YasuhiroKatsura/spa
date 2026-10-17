resource "aws_lb" "api" {
  name               = "${local.common.project_name}-alb-to-ecs4api"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [module.sg.security_group_ids.api_alb]
  subnets = [
    module.vpc.subnet.private_subnet_ids_by_name.alb_a,
    module.vpc.subnet.private_subnet_ids_by_name.alb_c,
  ]

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "api" {
  name        = "${local.common.project_name}-alb-tg-4api"
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
  name = "${local.common.project_name}-ecs-cluster4api"
}

resource "aws_ecs_task_definition" "api" {
  family                   = "${local.common.project_name}-ecs-task4api"
  cpu                      = local.container_conf.task_cpu
  memory                   = local.container_conf.task_memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = module.iam.task_execution_role_arn
  task_role_arn            = module.iam.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "${local.common.project_name}-ecs-container-4api"
      image     = "public.ecr.aws/nginx/nginx:${local.container_conf.image_tag}"
      essential = true
      portMappings = [{
        name          = "http"
        containerPort = 80
        hostPort      = 80
        protocol      = "tcp"
      }]
      environment = [
        { name = "DB_HOST", value = aws_rds_cluster.aurora.endpoint },
        { name = "DB_PORT", value = tostring(aws_rds_cluster.aurora.port) },
        { name = "DB_NAME", value = aws_rds_cluster.aurora.database_name },
        { name = "DB_USER", value = aws_rds_cluster.aurora.master_username },
      ]
      secrets = [{
        name      = "DB_PASSWORD"
        valueFrom = "${aws_rds_cluster.aurora.master_user_secret[0].secret_arn}:password::"
      }]
      readonlyRootFilesystem = false
      linuxParameters = {
        initProcessEnabled = true
      }
    }
  ])

  runtime_platform {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }
}

resource "aws_ecs_service" "api" {
  name                   = "${local.common.project_name}-ecs-service4api"
  cluster                = aws_ecs_cluster.api.id
  task_definition        = aws_ecs_task_definition.api.arn
  desired_count          = local.container_conf.desired_count
  enable_execute_command = true

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 100
  }

  network_configuration {
    subnets          = [module.vpc.subnet.private_subnet_ids_by_name.ecs_a]
    security_groups  = [module.sg.security_group_ids.api_tasks]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "${local.common.project_name}-ecs-container-4api"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.api]
}
