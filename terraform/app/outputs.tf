output "codedeploy_application_name" {
  description = "The name of the CodeDeploy application"
  value       = aws_codedeploy_app.mavis.name
}

output "codedeploy_deployment_group_name" {
  description = "The name of the CodeDeploy deployment group"
  value       = aws_codedeploy_deployment_group.blue_green_deployment_group.deployment_group_name
}

output "db_secret_arn" {
  description = "The ARN of the secret containing the DB credentials."
  value       = aws_rds_cluster.core.master_user_secret[0].secret_arn
}
