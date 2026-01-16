resource "aws_ssm_parameter" "core_environment_overwrites" {
  for_each = local.parameter_store_variables["CORE"]
  name     = "/${var.environment}/env/core/${each.key}"
  type     = "String"
  value    = each.value

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_ssm_parameter" "reporting_environment_overwrites" {
  for_each = local.parameter_store_variables["REPORTING"]
  name     = "/${var.environment}/env/reporting/${each.key}"
  type     = "String"
  value    = each.value

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_ssm_parameter" "prometheus_config" {
  name        = "${aws_ecs_cluster.cluster.name}-PrometheusConfig"
  type        = "String"
  tier        = "Standard"
  description = "Prometheus Scraping SSM Parameter for ECS Cluster: ${aws_ecs_cluster.cluster.name}"
  value = templatefile("templates/prometheus_exporter_config.yaml.tpl", {
    scrape_interval = "30s"
    scrape_timeout  = "10s"
  })
}

resource "aws_ssm_parameter" "cloudwatch_agent_config" {
  name        = "${aws_ecs_cluster.cluster.name}-CloudWatchAgentConfig"
  type        = "String"
  tier        = "Intelligent-Tiering"
  description = "CWAgent SSM Parameter for ECS Cluster: ${aws_ecs_cluster.cluster.name}"
  value = templatefile("templates/cloudwatch_agent_config.json.tpl", {
    log_group_name = aws_cloudwatch_log_group.ecs_log_group.name
  })
}
