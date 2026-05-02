# -----変数定義-----
variable "alb" {
  type = map(string)
  default = {
    name = "spa"
  }
}

#-----ALB-----
resource "aws_lb" "spa" {
  name               = "${var.alb.name}-alb"
  internal           = "false" # インターネットに公開
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.terraform_remote_state.landing_zone.outputs.ids.public_subnet_ids

  enable_deletion_protection = "false" # 削除保護は無効（個人利用なので...）
}

# -----リスナー-----
resource "aws_lb_listener" "spa" {
  load_balancer_arn = aws_lb.spa.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.s3_endpoint.arn
  }
}

# resource "aws_lb_listener_rule" "this" {
#   for_each = var.alb.listener_rules

#   listener_arn = xxx
#   priority     = xxx
#   }

# -----Target Group-----
resource "aws_lb_target_group" "s3_endpoint" {
  name        = "s3-endpoint-tg"
  port        = 443
  protocol    = "HTTPS" # S3エンドポイントとの通信はHTTPS
  vpc_id      = data.terraform_remote_state.landing_zone.outputs.ids.vpc_id
  target_type = "ip"

  health_check {
    protocol = "HTTPS"
    path     = "/" # S3の応答に合わせて200や307を許可
    matcher  = "200-399,405"
  }
}

resource "aws_lb_target_group_attachment" "spa_s3" {
  target_group_arn = aws_lb_target_group.s3_endpoint.arn
  target_id        = data.aws_network_interface.s3_endpoint.private_ip
  port             = 443
}

# -----security group-----
resource "aws_security_group" "alb" {
  name        = "${var.alb.name}-alb-sg"
  vpc_id      = data.terraform_remote_state.landing_zone.outputs.ids.vpc_id

  # インバウンドルール
  ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
