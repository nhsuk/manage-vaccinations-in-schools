environment         = "preview"
dns_certificate_arn = null
resource_name = {
  rds_security_group       = "mavis-preview-AddonsStack-1PD6PKSN106RK-dbDBClusterSecurityGroup-7cmoQwi6uv8e"
  loadbalancer             = "mavis-preview-pub-lb"
  lb_security_group        = "mavis-preview-PublicHTTPLoadBalancerSecurityGroup-qfHAKWH39OY3"
  cloudwatch_vpc_log_group = "mavis-preview-FlowLogs"
}
rails_master_key_path  = "/copilot/mavis/secrets/STAGING_RAILS_MASTER_KEY"
mise_sops_age_key_path = "/copilot/mavis/secrets/STAGING_MISE_SOPS_AGE_KEY"

http_hosts = {
  MAVIS__HOST                        = "preview.mavistesting.com"
  MAVIS__GIVE_OR_REFUSE_CONSENT_HOST = "preview.mavistesting.com"
}

valkey_node_type          = "cache.t4g.micro"
valkey_log_retention_days = 3
valkey_failover_enabled   = false

minimum_reporting_replicas = 2
maximum_reporting_replicas = 4
