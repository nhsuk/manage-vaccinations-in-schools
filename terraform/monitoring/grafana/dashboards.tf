locals {
  dashboard_path  = "${path.module}/resources/dashboards"
  dashboard_files = fileset(local.dashboard_path, "*.json")
}

resource "grafana_dashboard" "mavis" {
  for_each    = local.dashboard_files
  config_json = file("${local.dashboard_path}/${each.value}")
}
