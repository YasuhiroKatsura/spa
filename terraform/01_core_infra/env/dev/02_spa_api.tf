# -----変数定義-----
variable "spa_api" {
  type = map(string)
  default = {
  }
}

#-----ALB-----
resource "aws_lb" "alb_to_ecs4api" {
  name               = "${var.common.project_name}-alb-to-ecs4api"
  internal           = "true" # プライベート
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_on_alb_to_ecs4api.id]
  subnets            = [
    data.terraform_remote_state.landing_zone.outputs.ids.private_subnet_ids[0],
    data.terraform_remote_state.landing_zone.outputs.ids.private_subnet_ids[1]
  ]

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
  name        = "${var.common.project_name}-sg-on-alb-to-ecs4api"
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
