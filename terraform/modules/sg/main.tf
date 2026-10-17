variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

resource "aws_security_group" "api_tasks" {
  name        = "${var.project_name}-sg-on-ecs-service4api"
  description = "Security group for the API ECS service"
  vpc_id      = var.vpc_id
  egress      = []
}

resource "aws_security_group" "api_alb" {
  name        = "${var.project_name}-sg-on-alb-to-ecs4api"
  description = "Security group for the private API load balancer"
  vpc_id      = var.vpc_id
  egress      = []
}

resource "aws_security_group" "api_gateway_vpc_link" {
  name        = "${var.project_name}-sg-on-vpc-link"
  description = "Security group for the API Gateway VPC Link"
  vpc_id      = var.vpc_id
  egress      = []
}

resource "aws_security_group" "database" {
  name        = "${var.project_name}-sg-on-rds-aurora"
  description = "Security group for Aurora PostgreSQL"
  vpc_id      = var.vpc_id
  egress      = []
}

resource "aws_security_group" "frontend_alb" {
  name        = "${var.project_name}-sg-on-alb-to-s34front"
  description = "Security group for the public frontend load balancer"
  vpc_id      = var.vpc_id
  egress      = []
}

resource "aws_security_group" "frontend_endpoint" {
  name        = "${var.project_name}-sg-on-vpcendpt-to-s34front"
  description = "Security group for the frontend S3 VPC endpoint"
  vpc_id      = var.vpc_id
  egress      = []
}

resource "aws_vpc_security_group_ingress_rule" "api_alb_from_vpc_link" {
  security_group_id            = aws_security_group.api_alb.id
  description                  = "Allow API Gateway VPC Link traffic"
  referenced_security_group_id = aws_security_group.api_gateway_vpc_link.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "api_alb_all" {
  security_group_id = aws_security_group.api_alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
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

resource "aws_vpc_security_group_egress_rule" "api_gateway_to_alb" {
  security_group_id            = aws_security_group.api_gateway_vpc_link.id
  description                  = "Allow API Gateway VPC Link traffic to the API load balancer"
  referenced_security_group_id = aws_security_group.api_alb.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "database_from_api" {
  security_group_id            = aws_security_group.database.id
  description                  = "Allow PostgreSQL connections from the API tasks"
  referenced_security_group_id = aws_security_group.api_tasks.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "database_all" {
  security_group_id = aws_security_group.database.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "frontend_endpoint_from_alb" {
  security_group_id            = aws_security_group.frontend_endpoint.id
  description                  = "Allow HTTPS from the frontend load balancer"
  referenced_security_group_id = aws_security_group.frontend_alb.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "frontend_endpoint_all" {
  security_group_id = aws_security_group.frontend_endpoint.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "frontend_alb_http" {
  security_group_id = aws_security_group.frontend_alb.id
  description       = "Allow public HTTP traffic"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "frontend_alb_all" {
  security_group_id = aws_security_group.frontend_alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
