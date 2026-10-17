output "vpc" {
  value = aws_vpc.this
}

output "subnet" {
  value = {
    public_subnet_ids          = [for subnet in aws_subnet.public : subnet.id]
    private_subnet_ids         = [for subnet in aws_subnet.private : subnet.id]
    public_subnet_ids_by_name  = { for name, subnet in aws_subnet.public : name => subnet.id }
    private_subnet_ids_by_name = { for name, subnet in aws_subnet.private : name => subnet.id }
  }
}
