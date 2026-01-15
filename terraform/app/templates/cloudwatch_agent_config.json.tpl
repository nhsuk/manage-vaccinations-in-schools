{
  "logs": {
    "metrics_collected": {
      "prometheus": {
        "prometheus_config_path": "env:PROMETHEUS_CONFIG_CONTENT",
        "log_group_name": "${log_group_name}",
        "emf_processor": {
          "metric_declaration": [
            {
              "source_labels": [],
              "label_matcher": ".*",
              "dimensions": [["ClusterName"]],
              "metric_selectors": ["^.*$"]
            }
          ]
        }
      }
    },
    "force_flush_interval": 5
  }
}
