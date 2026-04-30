# ALB
resource "aws_lb" "this" {
  name               = var.alb_name
  internal           = var.is_internal
  load_balancer_type = "application"
  security_groups    = var.security_groups
  subnets            = var.subnet_ids

  enable_deletion_protection = var.enable_deletion_protection

  tags = merge(
    {
      Name = var.alb_name
    },
    var.tags
  )
}

# HTTPリスナー
resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.http_listener_port
  protocol          = "HTTP"

  # デフォルトアクション（パスに一致しない場合などの固定レスポンス）
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = var.default_response_message
      status_code  = var.default_response_status_code
    }
  }
}

# リスナールール
resource "aws_lb_listener_rule" "this" {
  for_each = var.listener_rules

  listener_arn = aws_lb_listener.this.arn
  priority     = each.value.priority

  # forward または redirect に応じて動的に action を作成
  dynamic "action" {
    for_each = [each.value.action]
    content {
      type             = action.value.type
      target_group_arn = try(action.value.target_group_arn, null)

      dynamic "redirect" {
        for_each = action.value.type == "redirect" && action.value.redirect != null ? [action.value.redirect] : []
        content {
          host        = try(redirect.value.host, "#{host}")
          path        = try(redirect.value.path, "/#{path}")
          port        = try(redirect.value.port, "#{port}")
          protocol    = try(redirect.value.protocol, "#{protocol}")
          status_code = redirect.value.status_code
        }
      }
    }
  }

  dynamic "condition" {
    for_each = [each.value.condition]
    content {
      dynamic "path_pattern" {
        for_each = condition.value.path_pattern != null ? [condition.value.path_pattern] : []
        content {
          values = path_pattern.value
        }
      }
      dynamic "host_header" {
        for_each = condition.value.host_header != null ? [condition.value.host_header] : []
        content {
          values = host_header.value
        }
      }
    }
  }
}