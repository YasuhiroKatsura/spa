# API Gateway設定
resource "aws_apigatewayv2_api" "api" {
  count         = var.resource_flags.api_stack_enabled ? 1 : 0
  name          = var.common.project_name
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "api" {
  count       = var.resource_flags.api_stack_enabled ? 1 : 0
  api_id      = aws_apigatewayv2_api.api[0].id
  name        = "dev"
  auto_deploy = true
}

resource "aws_apigatewayv2_route" "api" {
  count     = var.resource_flags.api_stack_enabled ? 1 : 0
  api_id    = aws_apigatewayv2_api.api[0].id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.api[0].id}"
}

resource "aws_apigatewayv2_integration" "api" {
  count                  = var.resource_flags.api_stack_enabled ? 1 : 0
  api_id                 = aws_apigatewayv2_api.api[0].id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  integration_uri        = aws_lb_listener.api[0].arn
  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.api[0].id
  payload_format_version = "1.0"
  timeout_milliseconds   = 30000
}

resource "aws_apigatewayv2_vpc_link" "api" {
  count = var.resource_flags.api_stack_enabled ? 1 : 0
  name  = "${var.common.project_name}-for-apigw"
  subnet_ids = [
    module.vpc.subnet.private_subnet_ids_by_name.alb_a,
    module.vpc.subnet.private_subnet_ids_by_name.alb_c,
  ]
  security_group_ids = [module.sg.id["vpc_link_for_apigw"]]
}

# ALB設定
resource "aws_lb" "api" {
  count              = var.resource_flags.api_stack_enabled ? 1 : 0
  name               = "${var.common.project_name}-for-ecs"
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
  count       = var.resource_flags.api_stack_enabled ? 1 : 0
  name        = "${var.common.project_name}-for-ecs"
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
  count             = var.resource_flags.api_stack_enabled ? 1 : 0
  load_balancer_arn = aws_lb.api[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api[0].arn
  }
}

# ECS設定
resource "aws_ecs_cluster" "api" {
  name = var.common.project_name
}

resource "aws_ecs_task_definition" "api_main" {
  count                    = var.resource_flags.rds_enabled ? 1 : 0
  family                   = "${var.common.project_name}-${var.api_ecs_conf.main.name}"
  cpu                      = var.api_ecs_conf.main.task_cpu
  memory                   = var.api_ecs_conf.main.task_memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = module.iam.arn["task_execution"] # ECS AgentがTask実行するための権限
  task_role_arn            = module.iam.arn["task"]           # ECS TaskがAWSリソースにアクセスするための権限

  container_definitions = templatefile(
    "${path.root}/templates/${var.api_ecs_conf.main.container_def_file}",
    {
      name          = "${var.common.project_name}-${var.api_ecs_conf.main.name}"
      db_host       = aws_rds_cluster.database[0].endpoint
      db_port       = tostring(aws_rds_cluster.database[0].port)
      db_name       = aws_rds_cluster.database[0].database_name
      db_user       = aws_rds_cluster.database[0].master_username
      db_secret_arn = aws_rds_cluster.database[0].master_user_secret[0].secret_arn
    }
  )

  runtime_platform {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }
}

resource "aws_ecs_service" "api_main" {
  count                  = var.resource_flags.api_tasks_enabled && var.resource_flags.rds_enabled ? 1 : 0
  name                   = "${var.common.project_name}-${var.api_ecs_conf.main.name}"
  cluster                = aws_ecs_cluster.api.id
  task_definition        = aws_ecs_task_definition.api_main[0].arn
  desired_count          = var.api_ecs_conf.main.desired_count
  enable_execute_command = true

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 100
  }

  network_configuration {
    subnets          = [module.vpc.subnet.private_subnet_ids_by_name.ecs_a]
    security_groups  = [module.sg.id["ecs_service_main"]]
    assign_public_ip = false
  }

  dynamic "load_balancer" {
    for_each = var.resource_flags.api_stack_enabled ? [true] : []
    content {
      target_group_arn = aws_lb_target_group.api[0].arn
      container_name   = "${var.common.project_name}-${var.api_ecs_conf.main.name}"
      container_port   = 80
    }
  }

  depends_on = [aws_lb_listener.api]
}
