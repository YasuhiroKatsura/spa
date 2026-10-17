output "connection" {
  value = {
    endpoint          = aws_rds_cluster.aurora.endpoint
    port              = aws_rds_cluster.aurora.port
    database_name     = aws_rds_cluster.aurora.database_name
    master_username   = aws_rds_cluster.aurora.master_username
    secret_arn        = aws_rds_cluster.aurora.master_user_secret[0].secret_arn
    security_group_id = aws_security_group.database.id
  }
}
