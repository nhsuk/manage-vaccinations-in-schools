output "grafana_endpoint" {
  value       = aws_grafana_workspace.this.endpoint
  description = "The endpoint URL for the Grafana workspace."
}

output "grafana_workspace_id" {
  value       = aws_grafana_workspace.this.id
  description = "The ID of the Grafana workspace."
}

output "service_account_id" {
  value       = aws_grafana_workspace_service_account.grafana_provider.service_account_id
  description = "The ID of the Grafana service account."
}

output "bucket_redirect_url" {
  value       = "http://${aws_s3_bucket_website_configuration.redirect.website_endpoint}"
  description = "The URL for the S3 bucket redirect to Grafana."
}
