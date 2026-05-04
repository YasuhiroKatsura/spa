# -----変数定義-----
variable "spa_front" {
  type = map(string)
  default = {
    name = "spa"
  }
}

#-----S3バケット-----
resource "aws_s3_bucket" "s34front" {
  bucket = aws_lb.alb_to_s34front.dns_name
}

resource "aws_s3_bucket_versioning" "s34front" {
  bucket = aws_s3_bucket.s34front.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_public_access_block" "s34front" {
  bucket                  = aws_s3_bucket.s34front.id
  block_public_acls       = "true" # public公開ACLの新規作成を禁止する
  ignore_public_acls      = "true" # 既存のpublic公開ACLを無視する
  block_public_policy     = "false" # Principal:*に設定されたバケットポリシーの作成を禁止しない(個人利用だし...)
  restrict_public_buckets = "false" # Principal:*に設定された既存バケットポリシーを無視しない
}

resource "aws_s3_bucket_policy" "s34front" {
  bucket = aws_s3_bucket.s34front.id
  policy = templatefile(
    "./03_bucket_policy_AllowVpcEndpointAccess.json",
    {
      bucket_name = aws_s3_bucket.s34front.bucket,
      vpc_endpoint_id = aws_vpc_endpoint.vpc_endpt_to_s34front.id
    }
  )
}

# -----VPCエンドポイント-----
resource "aws_vpc_endpoint" "vpc_endpt_to_s34front" {
  vpc_id             = data.terraform_remote_state.landing_zone.outputs.ids.vpc_id
  service_name       = "com.amazonaws.ap-northeast-1.s3"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = data.terraform_remote_state.landing_zone.outputs.ids.public_subnet_ids
  security_group_ids = [aws_security_group.sg_on_vpcendpt_to_s34front.id]
}

data "aws_network_interface" "vpc_endpt_to_s34front" {
  id = tolist(aws_vpc_endpoint.vpc_endpt_to_s34front.network_interface_ids)[0]
}

# -----security group (S3エンドポイント用)-----
resource "aws_security_group" "sg_on_vpcendpt_to_s34front" {
  name        = "${var.spa_front.name}-sg-on-vpcendpt-to-s34front"
  vpc_id      = data.terraform_remote_state.landing_zone.outputs.ids.vpc_id
}

resource "aws_security_group_rule" "sgrule_ingress_on_vpcendpt_to_s34front" {
  security_group_id = aws_security_group.sg_on_vpcendpt_to_s34front.id
  type                      = "ingress"
  from_port                 = "443"
  to_port                   = "443"
  protocol                  = "tcp"
  source_security_group_id  = aws_security_group.sg_on_alb_to_s34front.id
}

resource "aws_security_group_rule" "sgrule_egress_on_vpcendpt_to_s34front" {
  security_group_id = aws_security_group.sg_on_vpcendpt_to_s34front.id
  type             = "egress"
  from_port        = "0"
  to_port          = "0"
  protocol         = "-1"
  cidr_blocks      = ["0.0.0.0/0"]
}

#-----ALB-----
resource "aws_lb" "alb_to_s34front" {
  name               = "${var.spa_front.name}-alb-to-s34front"
  internal           = "false" # インターネットに公開
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_on_alb_to_s34front.id]
  subnets            = data.terraform_remote_state.landing_zone.outputs.ids.public_subnet_ids

  enable_deletion_protection = "false" # 削除保護は無効（個人利用なので...）
}

resource "aws_lb_listener" "alb_to_s34front" {
  load_balancer_arn = aws_lb.alb_to_s34front.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_to_s34front.arn
  }
}

resource "aws_lb_target_group" "alb_to_s34front" {
  name        = "${var.spa_front.name}-alb-to-s34front"
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

resource "aws_lb_target_group_attachment" "alb_to_s34front" {
  target_group_arn = aws_lb_target_group.alb_to_s34front.arn
  target_id        = data.aws_network_interface.vpc_endpt_to_s34front.private_ip
  port             = 443
}

# -----security group (ALB用)-----
resource "aws_security_group" "sg_on_alb_to_s34front" {
  name        = "${var.spa_front.name}-sg-on-alb-to-s34front"
  vpc_id      = data.terraform_remote_state.landing_zone.outputs.ids.vpc_id

  ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "sgrule_ingress_on_alb_to_s34front" {
  security_group_id = aws_security_group.sg_on_alb_to_s34front.id
  type             = "ingress"
  from_port        = "80"
  to_port          = "80"
  protocol         = "tcp"
  cidr_blocks      = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "sgrule_egress_on_alb_to_s34front" {
  security_group_id = aws_security_group.sg_on_alb_to_s34front.id
  type             = "egress"
  from_port        = "0"
  to_port          = "0"
  protocol         = "-1"
  cidr_blocks      = ["0.0.0.0/0"]
}