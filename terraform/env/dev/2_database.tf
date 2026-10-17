data "aws_subnet" "database_selected" {
  for_each = toset([
    module.vpc.subnet.private_subnet_ids_by_name.aurora_a,
    module.vpc.subnet.private_subnet_ids_by_name.aurora_c,
  ])
  id = each.value
}

resource "aws_rds_cluster" "aurora" {
  cluster_identifier          = "${local.common.project_name}-aurora-cluster"
  engine                      = "aurora-postgresql"
  engine_version              = local.db_conf.engine_version
  database_name               = "${local.common.project_name}AuroraDB"
  master_username             = "postgres"
  manage_master_user_password = true
  db_subnet_group_name        = aws_db_subnet_group.aurora.name
  vpc_security_group_ids      = [module.sg.security_group_ids.database]

  backup_retention_period      = local.db_conf.backup_retention_days
  preferred_backup_window      = "03:00-04:00"
  preferred_maintenance_window = "mon:04:00-mon:05:00"
  storage_encrypted            = true
  deletion_protection          = local.db_conf.deletion_protection
  skip_final_snapshot          = local.db_conf.skip_final_snapshot
}

resource "aws_rds_cluster_instance" "aurora" {
  count              = local.db_conf.instance_count
  cluster_identifier = aws_rds_cluster.aurora.id
  instance_class     = local.db_conf.instance_class
  engine             = aws_rds_cluster.aurora.engine
  engine_version     = aws_rds_cluster.aurora.engine_version

  performance_insights_enabled = local.db_conf.performance_insights_enabled
  auto_minor_version_upgrade   = true
}

resource "aws_db_subnet_group" "aurora" {
  name = "${local.common.project_name}-rds-subnet-group"
  subnet_ids = [
    module.vpc.subnet.private_subnet_ids_by_name.aurora_a,
    module.vpc.subnet.private_subnet_ids_by_name.aurora_c,
  ]

  lifecycle {
    precondition {
      condition     = alltrue([for subnet in data.aws_subnet.database_selected : subnet.vpc_id == module.vpc.vpc.id])
      error_message = "All database subnets must belong to the configured VPC."
    }
  }
}
