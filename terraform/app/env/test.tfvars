environment         = "test"
dns_certificate_arn = ["arn:aws:acm:eu-west-2:393416225559:certificate/265a02d0-9c37-42b6-be7e-e00e580718a8"]
resource_name = {
  rds_security_group       = "mavis-test-AddonsStack-GB8Z9LQVO8OF-dbDBClusterSecurityGroup-1KSO3O1CL4NI5"
  loadbalancer             = "mavis--Publi-W19xy2QLULZ4"
  lb_security_group        = "mavis-test-PublicHTTPLoadBalancerSecurityGroup-15LE48D6JYPML"
  cloudwatch_vpc_log_group = "mavis-test-FlowLogs"
}
rails_master_key_path  = "/copilot/mavis/secrets/STAGING_RAILS_MASTER_KEY"
mise_sops_age_key_path = "/copilot/mavis/secrets/STAGING_MISE_SOPS_AGE_KEY"

http_hosts = {
  MAVIS__HOST                        = "test.mavistesting.com"
  MAVIS__GIVE_OR_REFUSE_CONSENT_HOST = "test.mavistesting.com"
}

valkey_node_type          = "cache.t4g.micro"
valkey_log_retention_days = 3
valkey_failover_enabled   = false

minimum_reporting_replicas = 2
maximum_reporting_replicas = 4
