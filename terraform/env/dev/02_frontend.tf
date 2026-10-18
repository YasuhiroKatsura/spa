data "aws_caller_identity" "current" {} # AWS環境情報の取得

resource "aws_s3_bucket" "frontend" {
  bucket = "${var.common.project_name}-${var.common.env}-frontend-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket                  = aws_s3_bucket.frontend.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  policy = templatefile("${path.root}/templates/${var.frontend_s3_conf.bucket_policy_file}", {
    bucket_name     = aws_s3_bucket.frontend.bucket
    vpc_endpoint_id = aws_vpc_endpoint.s3.id
  })
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id             = module.vpc.vpc.id
  service_name       = "com.amazonaws.${var.common.region}.s3"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = module.vpc.subnet.public_subnet_ids
  security_group_ids = [module.sg.id["vpc_endpt_to_frontend"]]
}

data "aws_network_interface" "vpc_endpt_s3" {
  for_each = toset(aws_vpc_endpoint.s3.network_interface_ids)
  id       = each.value
}

resource "aws_lb" "frontend" {
  name               = "${var.common.project_name}-${var.common.env}-to-frontend"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.sg.id["frontend_alb"]]
  subnets            = module.vpc.subnet.public_subnet_ids

  enable_deletion_protection = false
}

resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_lb.frontend.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_lb_target_group" "frontend" {
  name        = "${var.common.project_name}-${var.common.env}-to-frontend"
  port        = 443
  protocol    = "HTTPS"
  vpc_id      = module.vpc.vpc.id
  target_type = "ip"

  health_check {
    protocol = "HTTPS"
    path     = "/"
    matcher  = "200-399,405"
  }
}

resource "aws_lb_target_group_attachment" "frontend" {
  for_each = data.aws_network_interface.vpc_endpt_s3

  target_group_arn = aws_lb_target_group.frontend.arn
  target_id        = each.value.private_ip
  port             = 443
}
