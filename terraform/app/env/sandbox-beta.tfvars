environment           = "sandbox-beta"
rails_master_key_path = "/copilot/mavis/secrets/STAGING_RAILS_MASTER_KEY"
dns_certificate_arn   = null
resource_name = {
  rds_security_group       = "mavis-sandbox-beta-rds-sg"
  loadbalancer             = "mavis-sandbox-beta-alb"
  lb_security_group        = "mavis-sandbox-beta-alb-sg"
  cloudwatch_vpc_log_group = "mavis-sandbox-beta-FlowLogs"
}
http_hosts = {
  MAVIS__HOST                        = "sandbox-beta.mavistesting.com"
  MAVIS__GIVE_OR_REFUSE_CONSENT_HOST = "sandbox-beta.mavistesting.com"
}

enable_splunk                   = false
enable_cis2                     = false
enable_pds_enqueue_bulk_updates = false

appspec_bucket           = "nhse-mavis-appspec-bucket-sandbox-beta"
minimum_web_replicas     = 1
maximum_web_replicas     = 2
minimum_sidekiq_replicas = 1
maximum_sidekiq_replicas = 2
good_job_replicas        = 1

# Valkey serverless configuration - minimal settings for sandbox
valkey_node_type          = "cache.t4g.micro"
valkey_log_retention_days = 3
valkey_failover_enabled   = false
sidekiq_replicas          = 1
