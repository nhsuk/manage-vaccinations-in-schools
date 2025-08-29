resource "aws_security_group" "rds_security_group" {
  name        = var.resource_name.rds_security_group
  description = "Allow inbound traffic only from app and all outbound traffic"
  vpc_id      = aws_vpc.application_vpc.id

  tags = {
    Name = "rds_security_group"
  }
  lifecycle {
    ignore_changes = [description]
  }
}

resource "aws_security_group_rule" "rds_ecs_ingress" {
  count                    = length(local.db_access_sg_ids)
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_security_group.id
  source_security_group_id = local.db_access_sg_ids[count.index]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_subnet_group" "core" {
  name        = "mavis-${var.environment}-core"
  subnet_ids  = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
  description = "Private subnets for the core aurora RDS cluster"
  tags = {
    name = "mavis-${var.environment}-core"
  }
}

resource "aws_rds_cluster" "core" {
  cluster_identifier                    = local.rds_cluster
  engine                                = "aurora-postgresql"
  engine_mode                           = "provisioned"
  engine_version                        = "16.8"
  database_name                         = "manage_vaccinations"
  master_username                       = "postgres"
  backup_retention_period               = var.backup_retention_period
  skip_final_snapshot                   = !local.is_production
  final_snapshot_identifier             = "${local.rds_cluster}-final-snapshot"
  db_subnet_group_name                  = aws_db_subnet_group.core.name
  vpc_security_group_ids                = [aws_security_group.rds_security_group.id]
  kms_key_id                            = aws_kms_key.rds_cluster.arn
  storage_encrypted                     = true
  manage_master_user_password           = true
  deletion_protection                   = true
  allow_major_version_upgrade           = true
  preferred_backup_window               = "01:00-01:30"
  preferred_maintenance_window          = "sun:02:30-sun:03:00"
  db_cluster_parameter_group_name       = aws_rds_cluster_parameter_group.custom_parameters.name
  database_insights_mode                = var.enable_enhanced_db_monitoring ? "advanced" : "standard"
  performance_insights_enabled          = var.enable_enhanced_db_monitoring
  performance_insights_retention_period = var.enable_enhanced_db_monitoring ? 465 : 0
  monitoring_interval                   = var.enable_enhanced_db_monitoring ? 30 : 0
  monitoring_role_arn                   = var.enable_enhanced_db_monitoring ? aws_iam_role.enhanced_db_monitoring[0].arn : null
  enabled_cloudwatch_logs_exports       = ["postgresql", "instance"]

  serverlessv2_scaling_configuration {
    max_capacity = var.max_aurora_capacity_units
    min_capacity = 0.5
  }

  tags = {
    NHSE-Enable-Backup = var.enable_backup_to_vault ? "True" : "False" # Required by the backup module to backup this resource
    environment_name   = var.environment                               # Required by the backup module to include in the backup framework compliance check
  }
}

resource "aws_secretsmanager_secret_rotation" "target" {
  secret_id          = aws_rds_cluster.core.master_user_secret[0].secret_arn
  rotate_immediately = false
  rotation_rules {
    schedule_expression = "cron(0 2 ? * WED#4 *)"
    duration            = "1h"
  }
}

resource "aws_rds_cluster_instance" "core" {
  for_each             = local.db_instances
  cluster_identifier   = aws_rds_cluster.core.id
  identifier           = "${local.rds_cluster}-${each.key}"
  instance_class       = "db.serverless"
  engine               = aws_rds_cluster.core.engine
  engine_version       = aws_rds_cluster.core.engine_version
  db_subnet_group_name = aws_db_subnet_group.core.name
  promotion_tier       = each.value["promotion_tier"]
  monitoring_interval  = var.enable_enhanced_db_monitoring ? 30 : 0
  monitoring_role_arn  = var.enable_enhanced_db_monitoring ? aws_iam_role.enhanced_db_monitoring[0].arn : null
}

resource "aws_rds_cluster_parameter_group" "custom_parameters" {
  family      = "aurora-postgresql16"
  name        = "cluster-group-${var.environment}"
  description = "Custom DB cluster parameter group"

  parameter {
    name  = "rds.force_ssl"
    value = 1 # true
  }

  dynamic "parameter" {
    for_each = var.enable_enhanced_db_monitoring ? {
      "aurora_compute_plan_id"                    = 1, # true
      "aurora_stat_plans.minutes_until_recapture" = 5,
      "log_parameter_max_length"                  = 0,
      "log_min_duration_statement"                = 1000,
      "log_line_prefix"                           = "%m:%r:%u@%d:[%p]:%l:%e:%s:%v:%x:%c:%q%a:"
    } : {}
    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  lifecycle {
    ignore_changes = [description]
  }
}

resource "aws_iam_role" "enhanced_db_monitoring" {
  count = var.enable_enhanced_db_monitoring ? 1 : 0
  name  = "enhanced-db-monitoring-role-${var.environment}"
  assume_role_policy = templatefile(
    "../app/templates/iam_assume_role.json.tpl",
  { service_name = "monitoring.rds.amazonaws.com" })
}

resource "aws_iam_role_policy_attachment" "enhanced_db_monitoring_policy" {
  count      = var.enable_enhanced_db_monitoring ? 1 : 0
  role       = aws_iam_role.enhanced_db_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
