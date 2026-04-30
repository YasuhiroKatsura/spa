output "alb_id" {
  description = "ALBのID"
  value       = aws_lb.this.id
}

output "alb_arn" {
  description = "ALBのARN"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "ALBのDNS名(アクセス用URL)"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "ALBのゾーンID(Route53のAliasレコード作成用)"
  value       = aws_lb.this.zone_id
}

output "http_listener_arn" {
  description = "HTTPリスナーのARN(リスナールール追加用)"
  value       = aws_lb_listener.this.arn
}