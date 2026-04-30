output "vpc_id" {
  value       = aws_vpc.this.id
  description = "VPCのID"
}

output "vpc_cidr_block" {
  value       = aws_vpc.this.cidr_block
  description = "VPCのCIDRブロック"
}