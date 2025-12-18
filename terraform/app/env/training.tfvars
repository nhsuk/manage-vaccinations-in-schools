environment = "training"
dns_certificate_arn = [
  "arn:aws:acm:eu-west-2:393416225559:certificate/368edbcb-37c5-4146-9087-ff011bef5e05",
  "arn:aws:acm:eu-west-2:393416225559:certificate/e93e3912-eee4-4f6e-826d-c628bff58527",
]
resource_name = {
  rds_security_group       = "mavis-training-AddonsStack-1JZSXP7P84221-dbDBClusterSecurityGroup-A5NL1GFJ83LX"
  loadbalancer             = "mavis--Publi-w1wzc4E2jrl6"
  lb_security_group        = "mavis-training-PublicHTTPLoadBalancerSecurityGroup-L8GOGS04ARYI"
  cloudwatch_vpc_log_group = "mavis-training-FlowLogs"
}
rails_master_key_path  = "/copilot/mavis/secrets/STAGING_RAILS_MASTER_KEY"
mise_sops_age_key_path = "/copilot/mavis/secrets/STAGING_MISE_SOPS_AGE_KEY"

http_hosts = {
  MAVIS__HOST                        = "training.manage-vaccinations-in-schools.nhs.uk"
  MAVIS__GIVE_OR_REFUSE_CONSENT_HOST = "training.give-or-refuse-consent-for-vaccinations.nhs.uk"
}

valkey_node_type          = "cache.t4g.micro"
valkey_log_retention_days = 3
valkey_failover_enabled   = false

minimum_reporting_replicas = 2
maximum_reporting_replicas = 4
