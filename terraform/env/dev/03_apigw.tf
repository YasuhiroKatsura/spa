resource "aws_apigatewayv2_api" "api" {
  name          = "${var.common.project_name}-apigw-to-ecs4api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "api" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = var.apigw_conf.stage
  auto_deploy = var.apigw_conf.auto_deploy
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
  integration_uri        = aws_lb_listener.api.arn
  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.api.id
  payload_format_version = "1.0"
  timeout_milliseconds   = 30000
}

resource "aws_apigatewayv2_vpc_link" "api" {
  name = "${var.common.project_name}-vpclink-to-ecs4api"
  subnet_ids = [
    module.vpc.subnet.private_subnet_ids_by_name.alb_a,
    module.vpc.subnet.private_subnet_ids_by_name.alb_c,
  ]
  security_group_ids = [module.sg.id["api_gateway_vpc_link"]]
}
