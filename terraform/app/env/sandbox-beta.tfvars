environment            = "sandbox-beta"
rails_master_key_path  = "/copilot/mavis/secrets/STAGING_RAILS_MASTER_KEY"
mise_sops_age_key_path = "/copilot/mavis/secrets/STAGING_MISE_SOPS_AGE_KEY"
dns_certificate_arn    = null
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

minimum_web_replicas       = 1
maximum_web_replicas       = 2
minimum_sidekiq_replicas   = 1
maximum_sidekiq_replicas   = 2
minimum_reporting_replicas = 1
maximum_reporting_replicas = 2

# Valkey serverless configuration - minimal settings for sandbox
valkey_node_type          = "cache.t4g.micro"
valkey_log_retention_days = 3
valkey_failover_enabled   = false
