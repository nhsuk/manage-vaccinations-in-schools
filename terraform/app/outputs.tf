output "db_secret_arn" {
  description = "The ARN of the secret containing the DB credentials."
  value       = aws_rds_cluster.core.master_user_secret[0].secret_arn
}
