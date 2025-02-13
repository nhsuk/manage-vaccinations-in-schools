output "s3_uri" {
  description = "S3 uri for appspec.yaml needed for CodeDeploy"
  value       = "s3://${aws_s3_bucket.code_deploy_bucket.bucket}/${aws_s3_object.appspec_object.key}"
}
