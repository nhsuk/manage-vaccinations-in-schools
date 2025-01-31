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

resource "aws_security_group_rule" "rds_ingress" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_security_group.id
  source_security_group_id = aws_security_group.ecs_service_sg.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "ecs_rds_egress" {
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.rds_security_group.id
  security_group_id        = aws_security_group.ecs_service_sg.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_subnet_group" "aurora_subnet_group" {
  name        = var.resource_name.dbsubnet_group
  description = "Group of private subnets for Aurora Serverless v2 cluster."
  subnet_ids  = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
  tags = {
    Name = "aurora-subnet-group-${var.environment_string}"
  }
}

resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier          = var.resource_name.db_cluster
  engine                      = "aurora-postgresql"
  engine_mode                 = "provisioned"
  engine_version              = "14.9"
  database_name               = "manage_vaccinations"
  master_username             = "postgres"
  manage_master_user_password = var.db_secret_arn == ""
  storage_encrypted           = true
  backup_retention_period     = var.backup_retention_period
  skip_final_snapshot         = !local.is_production
  db_subnet_group_name        = aws_db_subnet_group.aurora_subnet_group.name
  vpc_security_group_ids      = [aws_security_group.rds_security_group.id]
  deletion_protection         = var.rails_env != "development"

  serverlessv2_scaling_configuration {
    max_capacity = 8.0
    min_capacity = 0.5
  }
}

resource "aws_rds_cluster_instance" "aurora_instance" {
  cluster_identifier   = aws_rds_cluster.aurora_cluster.id
  instance_class       = "db.serverless"
  engine               = aws_rds_cluster.aurora_cluster.engine
  engine_version       = aws_rds_cluster.aurora_cluster.engine_version
  db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group.name
  promotion_tier       = 1
}
