environment         = "test"
dns_certificate_arn = ["arn:aws:acm:eu-west-2:393416225559:certificate/7e80f006-e9d8-488f-b950-d97f3cc41e4f"]
resource_name = {
  rds_security_group       = "mavis-test-AddonsStack-GB8Z9LQVO8OF-dbDBClusterSecurityGroup-1KSO3O1CL4NI5"
  loadbalancer             = "mavis--Publi-W19xy2QLULZ4"
  lb_security_group        = "mavis-test-PublicHTTPLoadBalancerSecurityGroup-15LE48D6JYPML"
  cloudwatch_vpc_log_group = "mavis-test-FlowLogs"
}
rails_master_key_path  = "/copilot/mavis/secrets/STAGING_RAILS_MASTER_KEY"
mise_sops_age_key_path = "/copilot/mavis/secrets/STAGING_MISE_SOPS_AGE_KEY"

# Normally this is 31, but this gives us 2 weeks of additional testing.
academic_year_number_of_preparation_days = 45

http_hosts = {
  MAVIS__HOST                        = "test.mavistesting.com"
  MAVIS__GIVE_OR_REFUSE_CONSENT_HOST = "test.mavistesting.com"
}

valkey_node_type          = "cache.t4g.micro"
valkey_log_retention_days = 3
valkey_failover_enabled   = false

active_target_group = "green"