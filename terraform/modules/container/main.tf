resource "aws_security_group" "api_tasks" {
  name        = "${var.common.project_name}-sg-on-ecs-service4api"
  description = "Security group for the API ECS service"
  vpc_id      = var.vpc_id
  egress      = []
}

resource "aws_security_group" "api_alb" {
  name        = "${var.common.project_name}-sg-on-alb-to-ecs4api"
  description = "Security group for the private API load balancer"
  vpc_id      = var.vpc_id
  egress      = []
}

resource "aws_vpc_security_group_ingress_rule" "api_tasks_from_alb" {
  security_group_id            = aws_security_group.api_tasks.id
  description                  = "Allow API load balancer traffic to ECS tasks"
  referenced_security_group_id = aws_security_group.api_alb.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "api_tasks_all" {
  security_group_id = aws_security_group.api_tasks.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "api_alb_all" {
  security_group_id = aws_security_group.api_alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "database_from_api" {
  security_group_id            = var.database.security_group_id
  description                  = "Allow PostgreSQL connections from the API tasks"
  referenced_security_group_id = aws_security_group.api_tasks.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

resource "aws_lb" "api" {
  name               = "${var.common.project_name}-alb-to-ecs4api"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.api_alb.id]
  subnets            = var.alb_subnet_ids

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "api" {
  name        = "${var.common.project_name}-alb-tg-4api"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
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
  cpu                      = var.settings.task_cpu
  memory                   = var.settings.task_memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = templatefile("${path.module}/templates/ecs_task4api.json", {
    name          = "${var.common.project_name}-ecs-container-4api"
    image_tag     = var.settings.image_tag
    db_host       = var.database.endpoint
    db_port       = var.database.port
    db_name       = var.database.database_name
    db_user       = var.database.master_username
    db_secret_arn = var.database.secret_arn
  })

  runtime_platform {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }
}

resource "aws_ecs_service" "api" {
  name                   = "${var.common.project_name}-ecs-service4api"
  cluster                = aws_ecs_cluster.api.id
  task_definition        = aws_ecs_task_definition.api.arn
  desired_count          = var.settings.desired_count
  enable_execute_command = true

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 100
  }

  network_configuration {
    subnets          = var.ecs_subnet_ids
    security_groups  = [aws_security_group.api_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "${var.common.project_name}-ecs-container-4api"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.api]
}

resource "aws_iam_role" "task_execution" {
  name = "${var.common.project_name}-ecs-task-execution-role-4api"

  assume_role_policy = templatefile("${path.module}/templates/trust_policy.json", {
    service = "ecs-tasks.amazonaws.com"
  })
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task" {
  name = "${var.common.project_name}-ecs-task-role-4api"

  assume_role_policy = templatefile("${path.module}/templates/trust_policy.json", {
    service = "ecs-tasks.amazonaws.com"
  })
}

resource "aws_iam_role_policy_attachment" "task_ssm" {
  role       = aws_iam_role.task.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "task_ssm_messages" {
  name   = "${var.common.project_name}-ecs-task-role-execute-command-policy-4api"
  role   = aws_iam_role.task.id
  policy = templatefile("${path.module}/templates/policy_connect_ssm.json", {})
}
