resource "aws_db_subnet_group" "dbsg" {
  name       = "${local.name_prefix}-subnet-group"
  subnet_ids = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
}

resource "aws_security_group" "rds" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_security_group_rule" "rds_inbound" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = module.db_access_service.security_group_id
}

resource "aws_rds_cluster" "cluster" {
  cluster_identifier     = "${local.name_prefix}-rds-${formatdate("hh-mm-ss", timestamp())}"
  engine                 = "aurora-postgresql"
  engine_mode            = "provisioned"
  database_name          = "manage_vaccinations"
  master_username        = "postgres"
  snapshot_identifier    = var.imported_snapshot
  db_subnet_group_name   = aws_db_subnet_group.dbsg.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  storage_encrypted      = true
  skip_final_snapshot    = true
  deletion_protection    = false
  engine_version         = var.db_engine_version

  serverlessv2_scaling_configuration {
    max_capacity = var.max_aurora_capacity_units
    min_capacity = 0.5
  }

  lifecycle {
    ignore_changes = [cluster_identifier]
  }
}

resource "aws_rds_cluster_instance" "instance" {
  cluster_identifier   = aws_rds_cluster.cluster.id
  identifier           = "${local.name_prefix}-rds-instance-${formatdate("hh-mm-ss", timestamp())}"
  instance_class       = "db.serverless"
  engine               = aws_rds_cluster.cluster.engine
  engine_version       = aws_rds_cluster.cluster.engine_version
  db_subnet_group_name = aws_db_subnet_group.dbsg.name
  promotion_tier       = 1

  lifecycle {
    ignore_changes = [identifier]
  }
}
