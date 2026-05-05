# -----変数定義-----
variable "spa_api" {
  type = map(string)
  default = {
    name = "spa"
    stage = "dev"
    auto_deploy = "true"
  }
}

# -----API Gateway v2 (HTTP API)-----
resource "aws_apigatewayv2_api" "apigw_to_ecs4api" {
  name          = "${var.spa_api.name}-apigw-to-ecs4api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "apigw_to_ecs4api" {
  api_id      = aws_apigatewayv2_api.apigw_to_ecs4api.id
  name        = "${var.spa_api.stage}"
  auto_deploy = var.spa_api.auto_deploy
}

resource "aws_apigatewayv2_integration" "apigw_to_ecs4api" {
  api_id             = aws_apigatewayv2_api.apigw_to_ecs4api.id
  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"
  integration_uri    = aws_lb_listener.alb_to_ecs4api.arn
  connection_type = "VPC_LINK"
  connection_id   = aws_apigatewayv2_vpc_link.vpclink_to_ecs4api.id
  payload_format_version = "1.0"
  timeout_milliseconds   = 30000
}

# -----VPC Link-----
resource "aws_apigatewayv2_vpc_link" "vpclink_to_ecs4api" {
  name = "${var.spa_api.name}-vpclink-to-ecs4api"

  subnet_ids = data.terraform_remote_state.landing_zone.outputs.ids.private_subnet_ids

  security_group_ids = [aws_security_group.sg_on_vpclink_to_ecs4api.id]
}

# -----security group (VPC Link用)-----
resource "aws_security_group" "sg_on_vpclink_to_ecs4api" {
  name        = "${var.spa_api.name}-sg-on-vpc-link"
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


#-----ALB-----
resource "aws_lb" "alb_to_ecs4api" {
  name               = "${var.spa_api.name}-alb-to-ecs4api"
  internal           = "true" # プライベート
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_on_alb_to_ecs4api.id]
  subnets            = data.terraform_remote_state.landing_zone.outputs.ids.private_subnet_ids

  enable_deletion_protection = "false" # 削除保護は無効（個人利用なので...）
}

resource "aws_lb_listener" "alb_to_ecs4api" {
  load_balancer_arn = aws_lb.alb_to_ecs4api.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "OK - default action"
      status_code  = "200"
    }
  }
}

# -----security group (ALB用)-----
resource "aws_security_group" "sg_on_alb_to_ecs4api" {
  name        = "${var.spa_api.name}-sg-on-alb-to-ecs4api"
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