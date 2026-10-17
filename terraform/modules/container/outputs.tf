output "alb_listener_arn" {
  value = aws_lb_listener.api.arn
}

output "security_group_ids" {
  value = {
    api_tasks = aws_security_group.api_tasks.id
    api_alb   = aws_security_group.api_alb.id
  }
}
