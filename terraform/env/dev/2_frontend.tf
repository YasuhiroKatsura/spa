data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "frontend" {
  bucket = "${local.common.project_name}-frontend-${data.aws_caller_identity.current.account_id}-${local.common.region}"
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
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowVpcEndpointAccess"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.frontend.arn}/*"
      Condition = {
        StringEquals = {
          "aws:sourceVpce" = aws_vpc_endpoint.s3.id
        }
      }
    }]
  })
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id             = module.vpc.vpc.id
  service_name       = "com.amazonaws.${local.common.region}.s3"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = module.vpc.subnet.public_subnet_ids
  security_group_ids = [module.sg.security_group_ids.frontend_endpoint]
}

data "aws_network_interface" "s3_endpoint" {
  for_each = toset(aws_vpc_endpoint.s3.network_interface_ids)
  id       = each.value
}

resource "aws_lb" "frontend" {
  name               = "${local.common.project_name}-alb-to-s34front"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.sg.security_group_ids.frontend_alb]
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
  name        = "${local.common.project_name}-alb-to-s34front"
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
  for_each = data.aws_network_interface.s3_endpoint

  target_group_arn = aws_lb_target_group.frontend.arn
  target_id        = each.value.private_ip
  port             = 443
}
