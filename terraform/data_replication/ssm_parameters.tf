# Create a password that is automatically populated in secrets manager using the random password generator for aws

# Generate a random password for the read-only database user
ephemeral "aws_secretsmanager_random_password" "ro_db_password" {
}

# Store the generated password in AWS Secrets Manager
resource "aws_secretsmanager_secret" "ro_db_password" {
  name                    = "${local.name_prefix}-ro-db-password-${substr(uuid(), 0, 4)}"
  description             = "Read-only database user password for data replication"
  recovery_window_in_days = 7

  tags = {
    Name = "${local.name_prefix}-ro-db-password"
  }
  lifecycle {
    ignore_changes = [name]
  }
}

resource "aws_secretsmanager_secret_version" "ro_db_password" {
  secret_id                = aws_secretsmanager_secret.ro_db_password.id
  secret_string_wo         = ephemeral.aws_secretsmanager_random_password.ro_db_password.random_password
  secret_string_wo_version = 1
}
