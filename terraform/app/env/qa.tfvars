environment         = "qa"
dns_certificate_arn = ["arn:aws:acm:eu-west-2:393416225559:certificate/dafb0f10-ee18-45e2-8971-28d4ab434375"]
resource_name = {
  rds_security_group       = "mavis-qa-AddonsStack-Z0L4GX5EUV3I-dbDBClusterSecurityGroup-vd2Avaw4JIgr"
  loadbalancer             = "mavis-qa-pub-lb"
  lb_security_group        = "mavis-qa-PublicHTTPLoadBalancerSecurityGroup-ml4lZT5ey5ih"
  cloudwatch_vpc_log_group = "mavis-qa-FlowLogs"
}
rails_master_key_path = "/copilot/mavis/secrets/STAGING_RAILS_MASTER_KEY"

http_hosts = {
  MAVIS__HOST                        = "qa.mavistesting.com"
  MAVIS__GIVE_OR_REFUSE_CONSENT_HOST = "qa.mavistesting.com"
}
max_aurora_capacity_units = 64
container_insights        = "enhanced"

enable_backup_to_vault        = true
enable_enhanced_db_monitoring = true
