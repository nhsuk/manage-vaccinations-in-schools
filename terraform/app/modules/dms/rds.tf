resource "aws_secretsmanager_secret_rotation" "source" {
  count              = var.source_managed_secret ? 1 : 0
  secret_id          = var.source_db_secret_arn
  rotate_immediately = false
  rotation_rules {
    schedule_expression = "rate(400 days)"
  }
}

resource "aws_secretsmanager_secret_rotation" "target" {
  secret_id          = var.target_db_secret_arn
  rotate_immediately = false
  rotation_rules {
    schedule_expression = "rate(400 days)"
  }
}
