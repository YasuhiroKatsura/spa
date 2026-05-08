# -----変数定義-----
variable "rds_aurora" {
  type = map(string)
  default = {
    engine_version  = "15.2"
    database_name   = "spadb"
    aurora_username = "postgres"
    aurora_password = ""
    instance_class  = "db.t3.micro"
    instance_count  = "1"
    backup_retention_days = "1" # バックアップ保持期間 (日数)
    deletion_protection = "false" # 削除保護は無効
    skip_final_snapshot     = "true"  # DB 削除時に最終バックアップを取らない
    performance_insights_enabled = "false" # パフォーマンスインサイトは無効
  }
}

# -----RDS Aurora DB Cluster-----
resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier      = "${var.common.project_name}-aurora-cluster"
  engine                  = "aurora-postgresql"
  engine_version          = "${var.rds_aurora.engine_version}"
  database_name           = "${var.common.project_name}-aurora-db"
  master_username         = "${var.rds_aurora.aurora_username}"
  master_password         = "${var.rds_aurora.aurora_password}"
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.sg_on_rds_aurora.id]
  
  backup_retention_period = "${var.rds_aurora.backup_retention_days}"
  preferred_backup_window = "03:00-04:00"
  preferred_maintenance_window = "mon:04:00-mon:05:00"
  
  storage_encrypted       = true
  deletion_protection     = ${var.rds_aurora.deletion_protection}
  skip_final_snapshot     = ${var.rds_aurora.skip_final_snapshot}
}

# -----RDS Aurora DB Instance-----
resource "aws_rds_cluster_instance" "aurora_instance" {
  count              = "${var.rds_aurora.instance_count}"
  cluster_identifier = aws_rds_cluster.aurora_cluster.id
  instance_class     = "${var.rds_aurora.instance_class}"
  engine              = "${var.rds_aurora.engine}"
  engine_version      = "${var.rds_aurora.engine_version}"

  performance_insights_enabled = "${var.rds_aurora.performance_insights_enabled}"
  auto_minor_version_upgrade   = true # マイナーバージョンの自動アップグレードを有効化
}

# -----IAM Policy for RDS Aurora Access-----
resource "aws_iam_role_policy" "policy_rds_access_for_ecs_task" {
  name = "${var.common.project_name}-ecs-task-role-rds-access-policy"
  role = aws_iam_role.role_ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds-db:connect"
        ]
        Resource = [
          "arn:aws:rds:${var.common.region}:*:dbuser:*/*"
        ]
      }
    ]
  })
}

# -----DB Subnet Group-----
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.common.project_name}-rds-subnet-group"
  subnet_ids = [
    data.terraform_remote_state.landing_zone.outputs.ids.private_subnet_ids[3],
    data.terraform_remote_state.landing_zone.outputs.ids.private_subnet_ids[4]
  ]
}

# -----Security Group (RDS Aurora用)-----
resource "aws_security_group" "sg_on_rds_aurora" {
  name        = "${var.common.project_name}-sg-on-rds-aurora"
  vpc_id      = data.terraform_remote_state.landing_zone.outputs.ids.vpc_id
  description = "Security group for Aurora PostgreSQL"
}

# ECS TaskからのPostgresアクセス
resource "aws_security_group_rule" "sgrule_ingress_postgres_from_ecs" {
  security_group_id = aws_security_group.sg_on_rds_aurora.id
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  source_security_group_id = aws_security_group.sg_on_ecs_service4api.id
}

# Egress rule
resource "aws_security_group_rule" "sgrule_egress_on_rds_aurora" {
  security_group_id = aws_security_group.sg_on_rds_aurora.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}