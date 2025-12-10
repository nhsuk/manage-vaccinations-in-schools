environment            = "performance"
rails_master_key_path  = "/copilot/mavis/secrets/STAGING_RAILS_MASTER_KEY"
mise_sops_age_key_path = "/copilot/mavis/secrets/STAGING_MISE_SOPS_AGE_KEY"
dns_certificate_arn    = null
resource_name = {
  rds_security_group       = "mavis-performance-rds-sg"
  loadbalancer             = "mavis-performance-alb"
  lb_security_group        = "mavis-performance-alb-sg"
  cloudwatch_vpc_log_group = "mavis-performance-FlowLogs"
}

http_hosts = {
  MAVIS__HOST                        = "performance.mavistesting.com"
  MAVIS__GIVE_OR_REFUSE_CONSENT_HOST = "performance.mavistesting.com"
}

max_aurora_capacity_units = 64
container_insights        = "enhanced"

enable_enhanced_db_monitoring = true
enable_backup_to_vault        = true

minimum_reporting_replicas = 2
maximum_reporting_replicas = 4
