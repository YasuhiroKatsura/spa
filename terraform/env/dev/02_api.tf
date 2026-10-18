resource "aws_apigatewayv2_api" "api" {
  name          = "${var.common.project_name}-${var.common.env}"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "api" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "dev"
  auto_deploy = true
}

resource "aws_apigatewayv2_route" "api" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.api.id}"
}

resource "aws_apigatewayv2_integration" "api" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  integration_uri        = aws_lb_listener.api.arn
  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.api.id
  payload_format_version = "1.0"
  timeout_milliseconds   = 30000
}

resource "aws_apigatewayv2_vpc_link" "api" {
  name = "${var.common.project_name}-${var.common.env}-for-apigw"
  subnet_ids = [
    module.vpc.subnet.private_subnet_ids_by_name.alb_a,
    module.vpc.subnet.private_subnet_ids_by_name.alb_c,
  ]
  security_group_ids = [module.sg.id["vpc_link_for_apigw"]]
}

resource "aws_lb" "api" {
  name               = "${var.common.project_name}-${var.common.env}-to-ecs"
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
  name        = "${var.common.project_name}-${var.common.env}-to-ecs"
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
  name = "${var.common.project_name}-${var.common.env}"
}

resource "aws_ecs_task_definition" "api_main" {
  family                   = "${var.common.project_name}-${var.common.env}-main"
  cpu                      = var.api_ecs_conf.api.task_cpu
  memory                   = var.api_ecs_conf.api.task_memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = module.iam.arn["task_execution"] # ECS AgentがTask実行するための権限
  task_role_arn            = module.iam.arn["task"]           # ECS TaskがAWSリソースにアクセスするための権限

  container_definitions = templatefile(
    "${path.root}/templates/${var.api_ecs_conf.api.container_def_file}",
    {
      db_host       = aws_rds_cluster.database.endpoint
      db_port       = tostring(aws_rds_cluster.database.port)
      db_name       = aws_rds_cluster.database.database_name
      db_user       = aws_rds_cluster.database.master_username
      db_secret_arn = aws_rds_cluster.database.master_user_secret[0].secret_arn
    }
  )

  runtime_platform {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }
}

resource "aws_ecs_service" "api_main" {
  name                   = "${var.common.project_name}-${var.common.env}-main"
  cluster                = aws_ecs_cluster.api.id
  task_definition        = aws_ecs_task_definition.api_main.arn
  desired_count          = var.api_ecs_conf.api.desired_count
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

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = var.api_ecs_conf.api.container_conf.name
    container_port   = 80
  }

  depends_on = [aws_lb_listener.api]
}
