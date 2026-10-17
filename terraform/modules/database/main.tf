data "aws_subnet" "selected" {
  for_each = toset(var.subnet_ids)
  id       = each.value
}

resource "aws_rds_cluster" "aurora" {
  cluster_identifier          = "${var.common.project_name}-aurora-cluster"
  engine                      = "aurora-postgresql"
  engine_version              = var.settings.engine_version
  database_name               = "${var.common.project_name}AuroraDB"
  master_username             = "postgres"
  manage_master_user_password = true
  db_subnet_group_name        = aws_db_subnet_group.aurora.name
  vpc_security_group_ids      = [var.security_group_id]

  backup_retention_period      = var.settings.backup_retention_days
  preferred_backup_window      = "03:00-04:00"
  preferred_maintenance_window = "mon:04:00-mon:05:00"
  storage_encrypted            = true
  deletion_protection          = var.settings.deletion_protection
  skip_final_snapshot          = var.settings.skip_final_snapshot
}

resource "aws_rds_cluster_instance" "aurora" {
  count              = var.settings.instance_count
  cluster_identifier = aws_rds_cluster.aurora.id
  instance_class     = var.settings.instance_class
  engine             = aws_rds_cluster.aurora.engine
  engine_version     = aws_rds_cluster.aurora.engine_version

  performance_insights_enabled = var.settings.performance_insights_enabled
  auto_minor_version_upgrade   = true
}

resource "aws_db_subnet_group" "aurora" {
  name       = "${var.common.project_name}-rds-subnet-group"
  subnet_ids = var.subnet_ids

  lifecycle {
    precondition {
      condition     = alltrue([for subnet in data.aws_subnet.selected : subnet.vpc_id == var.vpc_id])
      error_message = "All database subnets must belong to the configured VPC."
    }
  }
}
