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
  value = aws_s3_object.appspec_object.key
}

output "codedeploy_application_name" {
  description = "The name of the CodeDeploy application"
  value       = aws_codedeploy_app.mavis.name
}

output "codedeploy_deployment_group_name" {
  description = "The name of the CodeDeploy deployment group"
  value = aws_codedeploy_deployment_group.blue_green_deployment_group.deployment_group_name
}

output "mavis_cluster_name" {
  description = "The name of the ECS cluster"
  value       = aws_ecs_cluster.cluster.name
}

output "mavis_service_name" {
  description = "The name of the ECS service"
  value       = aws_ecs_service.service.name
}
