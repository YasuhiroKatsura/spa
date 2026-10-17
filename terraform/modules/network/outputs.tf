output "vpc" {
  value = aws_vpc.this
}

output "ids" {
  value = {
    vpc_id                     = aws_vpc.this.id
    vpc_cidr_block             = var.network.vpc.cidr_block
    public_subnet_ids          = [for subnet in aws_subnet.public : subnet.id]
    private_subnet_ids         = [for subnet in aws_subnet.private : subnet.id]
    public_subnet_ids_by_name  = { for name, subnet in aws_subnet.public : name => subnet.id }
    private_subnet_ids_by_name = { for name, subnet in aws_subnet.private : name => subnet.id }
    security_group_ids = {
      api_tasks            = aws_security_group.api_tasks.id
      api_alb              = aws_security_group.api_alb.id
      api_gateway_vpc_link = aws_security_group.api_gateway_vpc_link.id
      database             = aws_security_group.database.id
      frontend_alb         = aws_security_group.frontend_alb.id
      frontend_endpoint    = aws_security_group.frontend_endpoint.id
    }
  }
}
