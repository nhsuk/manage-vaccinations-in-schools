resource "grafana_rule_group" "rule_group_0000" {
  org_id           = 1
  name             = "QA-Database"
  folder_uid       = "database-folder"
  interval_seconds = 300

  rule {
    name      = "high-db-utilization-qa"
    condition = "C"

    data {
      ref_id = "A"

      relative_time_range {
        from = 600
        to   = 0
      }

      datasource_uid = "cloudwatch"
      model          = "{\"dimensions\":{\"DBClusterIdentifier\":\"mavis-qa\",\"Role\":\"*\"},\"expression\":\"\",\"id\":\"\",\"intervalMs\":1000,\"label\":\"\",\"logGroups\":[],\"matchExact\":true,\"maxDataPoints\":43200,\"metricEditorMode\":0,\"metricName\":\"CPUUtilization\",\"metricQueryType\":0,\"namespace\":\"AWS/RDS\",\"period\":\"\",\"queryMode\":\"Metrics\",\"refId\":\"A\",\"region\":\"eu-west-2\",\"sqlExpression\":\"\",\"statistic\":\"Average\"}"
    }
    data {
      ref_id = "B"

      relative_time_range {
        from = 600
        to   = 0
      }

      datasource_uid = "__expr__"
      model          = "{\"conditions\":[{\"evaluator\":{\"params\":[],\"type\":\"gt\"},\"operator\":{\"type\":\"and\"},\"query\":{\"params\":[\"B\"]},\"reducer\":{\"params\":[],\"type\":\"last\"},\"type\":\"query\"}],\"datasource\":{\"type\":\"__expr__\",\"uid\":\"__expr__\"},\"expression\":\"A\",\"intervalMs\":1000,\"maxDataPoints\":43200,\"reducer\":\"max\",\"refId\":\"B\",\"settings\":{\"mode\":\"\"},\"type\":\"reduce\"}"
    }
    data {
      ref_id = "C"

      relative_time_range {
        from = 600
        to   = 0
      }

      datasource_uid = "__expr__"
      model          = "{\"conditions\":[{\"evaluator\":{\"params\":[80],\"type\":\"gt\"},\"operator\":{\"type\":\"and\"},\"query\":{\"params\":[\"C\"]},\"reducer\":{\"params\":[],\"type\":\"last\"},\"type\":\"query\",\"unloadEvaluator\":{\"params\":[50],\"type\":\"lt\"}}],\"datasource\":{\"type\":\"__expr__\",\"uid\":\"__expr__\"},\"expression\":\"B\",\"intervalMs\":1000,\"maxDataPoints\":43200,\"refId\":\"C\",\"type\":\"threshold\"}"
    }

    no_data_state  = "NoData"
    exec_err_state = "KeepLast"
    for            = "5m"
    is_paused      = false

    notification_settings {
      receiver            = "grafana-default-sns"
      group_by            = null
      mute_time_intervals = null
    }
  }
}
resource "grafana_rule_group" "rule_group_0001" {
  org_id           = 1
  name             = "Capacity"
  folder_uid       = "ecs-folder"
  interval_seconds = 300

  rule {
    name      = "high-cpu-ecs-qa"
    condition = "C"

    data {
      ref_id = "A"

      relative_time_range {
        from = 600
        to   = 0
      }

      datasource_uid = "cloudwatch"
      model          = "{\"dimensions\":{\"ClusterName\":\"mavis-qa\",\"ServiceName\":\"*\"},\"expression\":\"\",\"id\":\"\",\"intervalMs\":1000,\"label\":\"\",\"logGroups\":[],\"matchExact\":true,\"maxDataPoints\":43200,\"metricEditorMode\":0,\"metricName\":\"CPUUtilization\",\"metricQueryType\":0,\"namespace\":\"AWS/ECS\",\"period\":\"\",\"queryMode\":\"Metrics\",\"refId\":\"A\",\"region\":\"default\",\"sqlExpression\":\"\",\"statistic\":\"Average\"}"
    }
    data {
      ref_id = "B"

      relative_time_range {
        from = 600
        to   = 0
      }

      datasource_uid = "__expr__"
      model          = "{\"conditions\":[{\"evaluator\":{\"params\":[],\"type\":\"gt\"},\"operator\":{\"type\":\"and\"},\"query\":{\"params\":[\"B\"]},\"reducer\":{\"params\":[],\"type\":\"last\"},\"type\":\"query\"}],\"datasource\":{\"type\":\"__expr__\",\"uid\":\"__expr__\"},\"expression\":\"A\",\"intervalMs\":1000,\"maxDataPoints\":43200,\"reducer\":\"mean\",\"refId\":\"B\",\"settings\":{\"mode\":\"dropNN\"},\"type\":\"reduce\"}"
    }
    data {
      ref_id = "C"

      relative_time_range {
        from = 600
        to   = 0
      }

      datasource_uid = "__expr__"
      model          = "{\"conditions\":[{\"evaluator\":{\"params\":[0],\"type\":\"gt\"},\"operator\":{\"type\":\"and\"},\"query\":{\"params\":[\"C\"]},\"reducer\":{\"params\":[],\"type\":\"last\"},\"type\":\"query\"}],\"datasource\":{\"type\":\"__expr__\",\"uid\":\"__expr__\"},\"expression\":\"B\",\"intervalMs\":1000,\"maxDataPoints\":43200,\"refId\":\"C\",\"type\":\"threshold\"}"
    }

    no_data_state  = "NoData"
    exec_err_state = "Error"
    for            = "5m"
    annotations = {
      __dashboardUid__ = "beqq06n8r5am8b"
      __panelId__      = "6"
    }
    is_paused = false

    notification_settings {
      receiver            = "Slack"
      group_by            = null
      mute_time_intervals = null
    }
  }
}
