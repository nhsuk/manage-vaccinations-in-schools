environment         = "preview"
dns_certificate_arn = null
docker_image        = "mavis/webapp"
resource_name = {
  rds_security_group       = "mavis-preview-AddonsStack-1PD6PKSN106RK-dbDBClusterSecurityGroup-7cmoQwi6uv8e"
  loadbalancer             = "mavis-preview-pub-lb"
  lb_security_group        = "mavis-preview-PublicHTTPLoadBalancerSecurityGroup-qfHAKWH39OY3"
  cloudwatch_vpc_log_group = "mavis-preview-FlowLogs"
}
rails_env             = "staging"
rails_master_key_path = "/copilot/mavis/secrets/STAGING_RAILS_MASTER_KEY"

enable_splunk                   = false
enable_cis2                     = false
enable_pds_enqueue_bulk_updates = false

http_hosts = {
  MAVIS__HOST                        = "preview.mavistesting.com"
  MAVIS__GIVE_OR_REFUSE_CONSENT_HOST = "preview.mavistesting.com"
}

appspec_bucket       = "nhse-mavis-appspec-bucket-preview"
minimum_web_replicas = 2
maximum_web_replicas = 4

valkey_node_type          = "cache.t4g.micro"
valkey_log_retention_days = 3
valkey_failover_enabled   = false
