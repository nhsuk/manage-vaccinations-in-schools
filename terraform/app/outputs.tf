output "s3_uri" {
  description = "S3 uri for appspec.yaml needed for CodeDeploy"
  value       = "s3://${aws_s3_bucket.code_deploy_bucket.bucket}/${aws_s3_object.appspec_object.key}"
}

output "s3_bucket" {
  description = "The name of the S3 bucket that stores the appspec.yaml for CodeDeploy"
  value       = aws_s3_bucket.code_deploy_bucket.bucket
}

output "s3_key" {
  description = "The key of the S3 CodeDeploy appspec object"
  value       = aws_s3_object.appspec_object.key
}

output "codedeploy_application_name" {
  description = "The name of the CodeDeploy application"
  value       = aws_codedeploy_app.mavis.name
}

output "codedeploy_deployment_group_name" {
  description = "The name of the CodeDeploy deployment group"
  value       = aws_codedeploy_deployment_group.blue_green_deployment_group.deployment_group_name
}

output "ecs_variables" {
  value = {
    cluster_name = aws_ecs_cluster.cluster.name
    good_job = {
      service_name    = module.good_job_service.service.name
      task_definition = module.good_job_service.task_definition
    }
  }
  description = "Essential attributes of the ECS service"
}

output "db_secret_arn" {
  description = "The ARN of the secret containing the DB credentials."
  value       = aws_rds_cluster.core.master_user_secret[0].secret_arn
}
