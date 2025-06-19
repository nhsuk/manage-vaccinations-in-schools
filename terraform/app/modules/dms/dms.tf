resource "aws_dms_replication_subnet_group" "dms_subnet_group" {
  replication_subnet_group_id          = "dms-subnet-group-${var.environment}"
  replication_subnet_group_description = "Subnet group for DMS replication instance"
  subnet_ids                           = var.subnet_ids
}

resource "aws_dms_replication_instance" "dms_instance" {
  replication_instance_id     = "${var.environment}-replication-instance"
  replication_instance_class  = "dms.t3.medium"
  vpc_security_group_ids      = [aws_security_group.dms.id]
  replication_subnet_group_id = aws_dms_replication_subnet_group.dms_subnet_group.id
  publicly_accessible         = false
}

resource "aws_dms_endpoint" "source" {
  endpoint_id                     = "source-endpoint-${var.environment}"
  endpoint_type                   = "source"
  engine_name                     = var.engine_name
  database_name                   = var.source_database_name
  secrets_manager_arn             = aws_secretsmanager_secret.source.arn
  secrets_manager_access_role_arn = aws_iam_role.secret_access.arn
  ssl_mode                        = "none"
  extra_connection_attributes = jsonencode({
    secretsManagerEndpointOverride = module.secretsmanager_vpc_endpoint.dns_name
    PluginName                     = "test_decoding"
  })
}

resource "aws_dms_endpoint" "target" {
  endpoint_id                     = "target-endpoint-${var.environment}"
  endpoint_type                   = "target"
  engine_name                     = var.engine_name
  database_name                   = var.target_database_name
  secrets_manager_arn             = aws_secretsmanager_secret.target.arn
  secrets_manager_access_role_arn = aws_iam_role.secret_access.arn
  ssl_mode                        = "none"
  extra_connection_attributes     = "secretsManagerEndpointOverride=${module.secretsmanager_vpc_endpoint.dns_name}"
}

resource "aws_dms_replication_task" "migration_task" {
  replication_task_id      = "migration-task-${var.environment}"
  migration_type           = "full-load-and-cdc"
  source_endpoint_arn      = aws_dms_endpoint.source.endpoint_arn
  target_endpoint_arn      = aws_dms_endpoint.target.endpoint_arn
  replication_instance_arn = aws_dms_replication_instance.dms_instance.replication_instance_arn
  table_mappings = jsonencode({
    rules = [
      {
        "rule-type" = "selection"
        "rule-id"   = "1"
        "rule-name" = "exclude_pglogical"
        "object-locator" = {
          "schema-name" = "pglogical"
          "table-name"  = "%"
        }
        "rule-action" = "exclude"
      },
      {
        "rule-type" = "selection"
        "rule-id"   = "2"
        "rule-name" = "include_all"
        "object-locator" = {
          "schema-name" = "%"
          "table-name"  = "%"
        }
        "rule-action" = "include"
      }
    ]
  })
  replication_task_settings = jsonencode({
    TargetMetadata = {
      TargetSchema       = "public",
      SupportLobs        = true,
      FullLobMode        = true,
      LimitedSizeLobMode = false,
      InlineLobMaxSize   = 32,
      LobChunkSize       = 64,
    },
    FullLoadSettings : {
      TargetTablePrepMode : "DO_NOTHING",
    },
    Logging = {
      EnableLogging : true
    }
  })
}
