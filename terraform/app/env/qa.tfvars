environment         = "qa"
dns_certificate_arn = ["arn:aws:acm:eu-west-2:393416225559:certificate/680d07ef-4d21-4a63-ab14-ffe34a143e93"]
resource_name = {
  rds_security_group       = "mavis-qa-AddonsStack-Z0L4GX5EUV3I-dbDBClusterSecurityGroup-vd2Avaw4JIgr"
  loadbalancer             = "mavis-qa-pub-lb"
  lb_security_group        = "mavis-qa-PublicHTTPLoadBalancerSecurityGroup-ml4lZT5ey5ih"
  cloudwatch_vpc_log_group = "mavis-qa-FlowLogs"
}
rails_master_key_path  = "/copilot/mavis/secrets/STAGING_RAILS_MASTER_KEY"
mise_sops_age_key_path = "/copilot/mavis/secrets/STAGING_MISE_SOPS_AGE_KEY"

http_hosts = {
  MAVIS__HOST                        = "qa.mavistesting.com"
  MAVIS__GIVE_OR_REFUSE_CONSENT_HOST = "qa.mavistesting.com"
}

enable_backup_to_vault    = true
max_aurora_capacity_units = 16

minimum_reporting_replicas = 2
maximum_reporting_replicas = 4

enable_ops_service = true
