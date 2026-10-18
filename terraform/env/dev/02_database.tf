data "aws_subnet" "this" {
  for_each = toset([
    module.vpc.subnet.private_subnet_ids_by_name.aurora_a,
    module.vpc.subnet.private_subnet_ids_by_name.aurora_c,
  ])
  id = each.value
}

resource "aws_rds_cluster" "this" {
  cluster_identifier          = "${var.common.project_name}-${var.common.env}"
  engine                      = "aurora-postgresql"
  engine_version              = var.database_rds_conf.engine_version
  database_name               = "${var.common.project_name}-${var.common.env}"
  master_username             = "postgres"
  manage_master_user_password = true
  db_subnet_group_name        = aws_db_subnet_group.aurora.name
  vpc_security_group_ids      = [module.sg.id["rds"]]

  backup_retention_period      = var.database_rds_conf.backup_retention_days
  preferred_backup_window      = "03:00-04:00"
  preferred_maintenance_window = "mon:04:00-mon:05:00"
  storage_encrypted            = true
  deletion_protection          = var.database_rds_conf.deletion_protection
  skip_final_snapshot          = var.database_rds_conf.skip_final_snapshot
}

resource "aws_rds_cluster_instance" "this" {
  count              = var.database_rds_conf.instance_count
  cluster_identifier = aws_rds_cluster.this.id
  instance_class     = var.database_rds_conf.instance_class
  engine             = aws_rds_cluster.this.engine
  engine_version     = aws_rds_cluster.this.engine_version

  performance_insights_enabled = var.database_rds_conf.performance_insights_enabled
  auto_minor_version_upgrade   = true
}

resource "aws_db_subnet_group" "this" {
  name = "${var.common.project_name}-${var.common.env}"
  subnet_ids = [
    module.vpc.subnet.private_subnet_ids_by_name.aurora_a,
    module.vpc.subnet.private_subnet_ids_by_name.aurora_c,
  ]

  lifecycle {
    precondition {
      condition     = alltrue([for subnet in data.aws_subnet.this : subnet.vpc_id == module.vpc.vpc.id])
      error_message = "All database subnets must belong to the configured VPC."
    }
  }
}
