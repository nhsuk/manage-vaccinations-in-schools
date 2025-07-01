output "grafana_endpoint" {
  value       = aws_grafana_workspace.this.endpoint
  description = "The endpoint URL for the Grafana workspace."
}
