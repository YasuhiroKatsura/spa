output "security_group_ids" {
  value = {
    api_tasks            = aws_security_group.api_tasks.id
    api_alb              = aws_security_group.api_alb.id
    api_gateway_vpc_link = aws_security_group.api_gateway_vpc_link.id
    database             = aws_security_group.database.id
    frontend_alb         = aws_security_group.frontend_alb.id
    frontend_endpoint    = aws_security_group.frontend_endpoint.id
  }
}
