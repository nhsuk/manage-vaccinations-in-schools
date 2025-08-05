resource "time_sleep" "target_secret_creation" {
  create_duration = "360s" # Avoid race condition with secret rotation on db creation
  triggers = {
    secret_arn = var.target_db_rotation_arn
  }
}

ephemeral "aws_secretsmanager_secret_version" "source_db_secret" {
  secret_id = var.source_db_secret_arn
}

ephemeral "aws_secretsmanager_secret_version" "target_db_secret" {
  secret_id  = var.target_db_secret_arn
  depends_on = [time_sleep.target_secret_creation]
}

locals {
  source_db_secret = jsondecode(ephemeral.aws_secretsmanager_secret_version.source_db_secret.secret_string)
  target_db_secret = jsondecode(ephemeral.aws_secretsmanager_secret_version.target_db_secret.secret_string)
}

resource "aws_secretsmanager_secret" "source" {
  name = "dms_temporary_secret_source_${var.environment}"
}

resource "aws_secretsmanager_secret" "target" {
  name = "dms_temporary_secret_target_${var.environment}"
}

resource "aws_secretsmanager_secret_version" "source" {
  secret_id = aws_secretsmanager_secret.source.id
  secret_string_wo = jsonencode({
    port : var.source_port,
    host : var.source_endpoint,
    server_name : var.source_database_name,
    username : local.source_db_secret["username"],
    password : local.source_db_secret["password"],
    dbClusterIdentifier : var.source_database_name,
    }
  )
  secret_string_wo_version = 1
}

resource "aws_secretsmanager_secret_version" "target" {
  secret_id = aws_secretsmanager_secret.target.id
  secret_string_wo = jsonencode({
    port : var.target_port,
    host : var.target_endpoint,
    dbname : var.target_database_name,
    username : local.target_db_secret["username"],
    password : local.target_db_secret["password"],
    dbClusterIdentifier : var.target_database_name,
    }
  )
  secret_string_wo_version = 1
}
