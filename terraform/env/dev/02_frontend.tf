data "aws_caller_identity" "current" {} # AWS環境情報の取得

# S3設定
resource "aws_s3_bucket" "frontend" {
  count  = var.resource_flags.s3_enabled ? 1 : 0
  bucket = "${var.common.project_name}-${data.aws_caller_identity.current.account_id}.ap-northeast-1.elb.amazonaws.com" # ALBのDNS名とバケット名を一致させる
}

resource "aws_s3_bucket_versioning" "frontend" {
  count  = var.resource_flags.s3_enabled ? 1 : 0
  bucket = aws_s3_bucket.frontend[0].id

  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  count                   = var.resource_flags.s3_enabled ? 1 : 0
  bucket                  = aws_s3_bucket.frontend[0].id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "frontend" {
  count  = var.resource_flags.s3_enabled && var.resource_flags.frontend_edge_enabled ? 1 : 0
  bucket = aws_s3_bucket.frontend[0].id
  policy = templatefile("${path.root}/templates/${var.frontend_s3_conf.bucket_policy_file}", {
    bucket_name     = aws_s3_bucket.frontend[0].bucket
    vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
  })
}

resource "aws_vpc_endpoint" "s3" {
  count              = var.resource_flags.frontend_edge_enabled ? 1 : 0
  vpc_id             = module.vpc.vpc.id
  service_name       = "com.amazonaws.${var.common.region}.s3"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = module.vpc.subnet.public_subnet_ids
  security_group_ids = [module.sg.id["vpc_endpt_for_s3"]]
}

data "aws_network_interface" "vpc_endpt_s3" {
  for_each = var.resource_flags.frontend_edge_enabled ? var.vpc_conf.public_subnets : {}

  filter {
    name   = "description"
    values = ["VPC Endpoint Interface ${aws_vpc_endpoint.s3[0].id}"]
  }

  filter {
    name   = "subnet-id"
    values = [module.vpc.subnet.public_subnet_ids_by_name[each.key]]
  }

  filter {
    name   = "interface-type"
    values = ["vpc_endpoint"]
  }
}

# ALB設定
resource "aws_lb" "frontend" {
  count              = var.resource_flags.frontend_edge_enabled ? 1 : 0
  name               = var.common.project_name # FQDN: ${var.common.project_name}.ap-northeast-1.elb.amazonaws.com
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.sg.id["frontend_alb"]]
  subnets            = module.vpc.subnet.public_subnet_ids

  enable_deletion_protection = false
}

resource "aws_lb_listener" "frontend" {
  count             = var.resource_flags.frontend_edge_enabled ? 1 : 0
  load_balancer_arn = aws_lb.frontend[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend[0].arn
  }
}

resource "aws_lb_target_group" "frontend" {
  count       = var.resource_flags.frontend_edge_enabled ? 1 : 0
  name        = "${var.common.project_name}-for-s3"
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

  target_group_arn = aws_lb_target_group.frontend[0].arn
  target_id        = each.value.private_ip
  port             = 443
}
