output "id" {
  value = {
    for name, security_group in aws_security_group.this : name => security_group.id
  }
}
