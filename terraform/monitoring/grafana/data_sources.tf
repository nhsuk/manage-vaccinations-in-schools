resource "grafana_data_source" "cloudwatch" {
  name = "CloudWatch"
  type = "cloudwatch"
  json_data_encoded = jsonencode({
    authType      = "default"
    defaultRegion = var.region
  })
}
