output "bucket_id" {
  value       = aws_s3_bucket.this.id
  description = "The ID of the S3 bucket"
}

output "arn" {
  value       = aws_s3_bucket.this.arn
  description = "The ARN of the S3 bucket"
}

output "bucket_regional_domain_name" {
  value       = aws_s3_bucket.this.bucket_regional_domain_name
  description = "The Regional domain name of the S3 bucket"
}
