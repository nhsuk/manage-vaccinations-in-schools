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
  count                    = length(local.ecs_sg_ids)
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_security_group.id
  source_security_group_id = local.ecs_sg_ids[count.index]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_subnet_group" "aurora_subnet_group" {
  name        = var.resource_name.dbsubnet_group
  description = "Group of private subnets for Aurora Serverless v2 cluster."
  subnet_ids  = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
  tags = {
    Name = "aurora-subnet-group-${var.environment}"
  }
}

resource "aws_rds_cluster_parameter_group" "migration_source" {
  name        = "${var.environment}-custom"
  family      = "aurora-postgresql16"
  description = "Custom parameter group for Aurora PostgreSQL cluster"

  parameter {
    name         = "rds.logical_replication"
    value        = 1
    apply_method = "pending-reboot"
  }
}

resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier              = var.resource_name.db_cluster
  engine                          = "aurora-postgresql"
  engine_mode                     = "provisioned"
  engine_version                  = "16.8"
  database_name                   = "manage_vaccinations"
  master_username                 = "postgres"
  manage_master_user_password     = var.db_secret_arn == null
  storage_encrypted               = true
  backup_retention_period         = var.backup_retention_period
  skip_final_snapshot             = !local.is_production
  db_subnet_group_name            = aws_db_subnet_group.aurora_subnet_group.name
  vpc_security_group_ids          = [aws_security_group.rds_security_group.id]
  deletion_protection             = true
  allow_major_version_upgrade     = true
  preferred_backup_window         = "01:00-01:30"
  preferred_maintenance_window    = "sun:02:30-sun:03:00"
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.migration_source.name

  serverlessv2_scaling_configuration {
    max_capacity = var.max_aurora_capacity_units
    min_capacity = 0.5
  }

  tags = {
    NHSE-Enable-Backup = var.enable_backup_to_vault ? "True" : "False" # Required by the backup module to backup this resource
    environment_name   = var.environment                               # Required by the backup module to include in the backup framework compliance check
  }
}

resource "aws_rds_cluster_instance" "aurora_instance" {
  cluster_identifier   = aws_rds_cluster.aurora_cluster.id
  identifier           = var.resource_name.db_instance
  instance_class       = "db.serverless"
  engine               = aws_rds_cluster.aurora_cluster.engine
  engine_version       = aws_rds_cluster.aurora_cluster.engine_version
  db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group.name
  promotion_tier       = 1
}

resource "aws_rds_cluster_instance" "old_read_replica" {
  cluster_identifier   = aws_rds_cluster.aurora_cluster.id
  identifier           = "mavis-${var.environment}-rds-read-instance"
  instance_class       = "db.serverless"
  engine               = aws_rds_cluster.aurora_cluster.engine
  engine_version       = aws_rds_cluster.aurora_cluster.engine_version
  db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group.name
  promotion_tier       = 1
}


resource "aws_rds_cluster_parameter_group" "migration_target" {
  name        = "${var.environment}-disable-constraints"
  family      = "aurora-postgresql16"
  description = "Custom parameter group for Aurora PostgreSQL cluster"

  parameter {
    name         = "session_replication_role"
    value        = "replica"
    apply_method = "immediate"
  }
}

resource "aws_rds_cluster" "core" {
  cluster_identifier              = "mavis-${var.environment}"
  engine                          = "aurora-postgresql"
  engine_mode                     = "provisioned"
  engine_version                  = "16.8"
  database_name                   = "manage_vaccinations"
  master_username                 = "postgres"
  backup_retention_period         = var.backup_retention_period
  skip_final_snapshot             = !local.is_production
  db_subnet_group_name            = aws_db_subnet_group.aurora_subnet_group.name
  vpc_security_group_ids          = [aws_security_group.rds_security_group.id]
  kms_key_id                      = aws_kms_key.rds_cluster.arn
  storage_encrypted               = true
  manage_master_user_password     = true
  enable_http_endpoint            = true
  deletion_protection             = true
  allow_major_version_upgrade     = true
  preferred_backup_window         = "01:00-01:30"
  preferred_maintenance_window    = "sun:02:30-sun:03:00"
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.migration_target.name

  serverlessv2_scaling_configuration {
    max_capacity = var.max_aurora_capacity_units
    min_capacity = 0.5
  }
}

resource "aws_secretsmanager_secret_rotation" "target" {
  secret_id          = aws_rds_cluster.core.master_user_secret[0].secret_arn
  rotate_immediately = false
  rotation_rules {
    schedule_expression = "rate(400 days)"
  }
}

resource "aws_rds_cluster_instance" "core" {
  for_each             = local.db_instances
  cluster_identifier   = aws_rds_cluster.core.id
  identifier           = "mavis-${var.environment}-${each.key}"
  instance_class       = "db.serverless"
  engine               = aws_rds_cluster.core.engine
  engine_version       = aws_rds_cluster.core.engine_version
  db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group.name
  promotion_tier       = each.value["promotion_tier"]
}
