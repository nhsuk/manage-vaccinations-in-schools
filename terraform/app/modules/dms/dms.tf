
resource "aws_dms_replication_subnet_group" "dms_subnet_group" {
  replication_subnet_group_id          = "dms-subnet-group"
  replication_subnet_group_description = "Subnet group for DMS replication instance"
  subnet_ids                           = var.subnet_ids
  depends_on                           = [aws_iam_role.dms_vpc_role]
}

resource "aws_security_group" "dms" {
  name        = "dms-security-group"
  description = "Security group for DMS replication instance"
  vpc_id      = var.vpc_id

  tags = {
    Name = "dms-security-group-${var.environment}"
  }
}

resource "aws_security_group_rule" "dms_ingress" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = var.rds_cluster_security_group_id
  source_security_group_id = aws_security_group.dms.id
}

resource "aws_dms_replication_instance" "dms_instance" {
  replication_instance_id     = "dms-replication-instance"
  replication_instance_class  = "dms.t3.medium"
  vpc_security_group_ids      = [aws_security_group.dms.id]
  replication_subnet_group_id = aws_dms_replication_subnet_group.dms_subnet_group.id
  publicly_accessible         = false
}

resource "aws_security_group_rule" "egress_to_rds" {
  type                     = "egress"
  from_port                = var.source_port
  to_port                  = var.source_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.dms.id
  source_security_group_id = var.rds_cluster_security_group_id
}

module "secretsmanager_vpc_endpoint" {
  source                = "../vpc_endpoint"
  ingress_ports         = ["443"]
  service_name          = "com.amazonaws.eu-west-2.secretsmanager"
  source_security_group = aws_security_group.dms.id
  subnet_ids            = var.subnet_ids
  vpc_id                = var.vpc_id
  tags = {
    Name = "SecretsManager VPC Endpoint - ${var.environment}"
  }
}

resource "aws_dms_endpoint" "source" {
  endpoint_id                     = "source-endpoint"
  endpoint_type                   = "source"
  engine_name                     = var.engine_name
  database_name                   = var.source_database_name
  secrets_manager_arn             = aws_secretsmanager_secret.source.arn
  secrets_manager_access_role_arn = aws_iam_role.secret_access.arn
  ssl_mode                        = "none"
  extra_connection_attributes     = "secretsManagerEndpointOverride=${module.secretsmanager_vpc_endpoint.dns_name}"
}

resource "aws_dms_endpoint" "target" {
  endpoint_id                     = "target-endpoint"
  endpoint_type                   = "target"
  engine_name                     = var.engine_name
  database_name                   = var.target_database_name
  secrets_manager_arn             = aws_secretsmanager_secret.source.arn
  secrets_manager_access_role_arn = aws_iam_role.secret_access.arn
  ssl_mode                        = "none"
  extra_connection_attributes     = "secretsManagerEndpointOverride=${module.secretsmanager_vpc_endpoint.dns_name}"
}

resource "aws_dms_replication_task" "migration_task" {
  replication_task_id      = "migration-task"
  migration_type           = "full-load-and-cdc"
  source_endpoint_arn      = aws_dms_endpoint.source.endpoint_arn
  target_endpoint_arn      = aws_dms_endpoint.target.endpoint_arn
  replication_instance_arn = aws_dms_replication_instance.dms_instance.replication_instance_arn
  table_mappings = jsonencode({
    rules = [{
      rule-type = "selection"
      rule-id   = "1"
      rule-name = "1"
      object-locator = {
        schema-name = "%"
        table-name  = "%"
      }
      rule-action = "include"
    }]
  })
}
