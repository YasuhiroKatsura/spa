# -----変数定義-----
variable "spa_apigw" {
  type = map(string)
  default = {
    stage = "dev"
    auto_deploy = "true"
  }
}

# -----API Gateway v2 (HTTP API)-----
resource "aws_apigatewayv2_api" "apigw_to_ecs4api" {
  name          = "${var.common.project_name}-apigw-to-ecs4api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "apigw_to_ecs4api" {
  api_id      = aws_apigatewayv2_api.apigw_to_ecs4api.id
  name        = "${var.spa_apigw.stage}"
  auto_deploy = var.spa_apigw.auto_deploy
}

resource "aws_apigatewayv2_route" "apigw_route_4api" {
  api_id    = aws_apigatewayv2_api.apigw_to_ecs4api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.apigw_to_ecs4api.id}"
}

resource "aws_apigatewayv2_integration" "apigw_to_ecs4api" {
  api_id             = aws_apigatewayv2_api.apigw_to_ecs4api.id
  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"
  integration_uri    = "http://${aws_lb.alb_to_ecs4api.dns_name}"
  connection_type = "VPC_LINK"
  connection_id   = aws_apigatewayv2_vpc_link.vpclink_to_ecs4api.id
  payload_format_version = "1.0"
  timeout_milliseconds   = 30000
}

# -----VPC Link-----
resource "aws_apigatewayv2_vpc_link" "vpclink_to_ecs4api" {
  name = "${var.common.project_name}-vpclink-to-ecs4api"

  subnet_ids = [
    data.terraform_remote_state.landing_zone.outputs.ids.private_subnet_ids[0],
    data.terraform_remote_state.landing_zone.outputs.ids.private_subnet_ids[1]
  ]

  security_group_ids = [aws_security_group.sg_on_vpclink_to_ecs4api.id]
}

# -----security group (VPC Link用)-----
resource "aws_security_group" "sg_on_vpclink_to_ecs4api" {
  name        = "${var.common.project_name}-sg-on-vpc-link"
  vpc_id      = data.terraform_remote_state.landing_zone.outputs.ids.vpc_id
}

resource "aws_security_group_rule" "sgrule_egress_on_vpclink_to_ecs4api" {
  security_group_id = aws_security_group.sg_on_vpclink_to_ecs4api.id
  type                     = "egress"
  from_port                = "80"
  to_port                  = "80"
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.sg_on_alb_to_ecs4api.id
}
