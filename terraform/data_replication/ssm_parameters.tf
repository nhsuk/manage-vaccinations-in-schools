ephemeral "aws_secretsmanager_random_password" "read_only_db_password" {
}

resource "aws_secretsmanager_secret" "read_only_db_password" {
  name                    = "${local.name_prefix}-grafana-read-only-db-password-${substr(uuid(), 0, 4)}"
  description             = "Read-only database user password for data replication"
  recovery_window_in_days = 7

  tags = {
    Name = "${local.name_prefix}-read-only-db-password"
  }
  lifecycle {
    ignore_changes = [name]
  }
}

resource "aws_secretsmanager_secret_version" "read_only_db_password" {
  secret_id                = aws_secretsmanager_secret.read_only_db_password.id
  secret_string_wo         = ephemeral.aws_secretsmanager_random_password.read_only_db_password.random_password
  secret_string_wo_version = 1
}
