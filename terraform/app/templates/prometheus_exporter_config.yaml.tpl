global:
  scrape_interval: ${scrape_interval}
  scrape_timeout: ${scrape_timeout}
scrape_configs:
  - job_name: mavis-metrics
    static_configs:
      - targets: ['localhost:9394']
    metrics_path: /metrics
