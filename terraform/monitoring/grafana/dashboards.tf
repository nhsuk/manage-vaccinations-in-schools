resource "grafana_dashboard" "database_dashboard" {
  config_json = templatefile("${path.module}/resources/database-dashboard.json", {
    grafana_data_source_cloudwatch_uid = grafana_data_source.cloudwatch.uid
    region                             = var.region
  })
}
