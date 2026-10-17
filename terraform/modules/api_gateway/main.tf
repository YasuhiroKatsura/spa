resource "aws_security_group" "vpc_link" {
  name        = "${var.common.project_name}-sg-on-vpc-link"
  description = "Security group for the API Gateway VPC Link"
  vpc_id      = var.vpc_id
  egress      = []
}

resource "aws_vpc_security_group_ingress_rule" "api_alb_from_vpc_link" {
  security_group_id            = var.api_alb_security_group_id
  description                  = "Allow API Gateway VPC Link traffic"
  referenced_security_group_id = aws_security_group.vpc_link.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "vpc_link_to_alb" {
  security_group_id            = aws_security_group.vpc_link.id
  description                  = "Allow API Gateway VPC Link traffic to the API load balancer"
  referenced_security_group_id = var.api_alb_security_group_id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

resource "aws_apigatewayv2_api" "api" {
  name          = "${var.common.project_name}-apigw-to-ecs4api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "api" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = var.settings.stage
  auto_deploy = var.settings.auto_deploy
}

resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.api.id}"
}

resource "aws_apigatewayv2_integration" "api" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  integration_uri        = var.api_listener_arn
  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.api.id
  payload_format_version = "1.0"
  timeout_milliseconds   = 30000
}

resource "aws_apigatewayv2_vpc_link" "api" {
  name               = "${var.common.project_name}-vpclink-to-ecs4api"
  subnet_ids         = var.private_subnet_ids
  security_group_ids = [aws_security_group.vpc_link.id]
}
