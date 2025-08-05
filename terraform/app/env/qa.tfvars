environment         = "qa"
dns_certificate_arn = ["arn:aws:acm:eu-west-2:393416225559:certificate/dafb0f10-ee18-45e2-8971-28d4ab434375"]
docker_image        = "mavis/webapp"
resource_name = {
  rds_security_group       = "mavis-qa-AddonsStack-Z0L4GX5EUV3I-dbDBClusterSecurityGroup-vd2Avaw4JIgr"
  loadbalancer             = "mavis-qa-pub-lb"
  lb_security_group        = "mavis-qa-PublicHTTPLoadBalancerSecurityGroup-ml4lZT5ey5ih"
  cloudwatch_vpc_log_group = "mavis-qa-FlowLogs"
}
rails_env             = "staging"
rails_master_key_path = "/copilot/mavis/secrets/STAGING_RAILS_MASTER_KEY"

enable_cis2                     = false
enable_pds_enqueue_bulk_updates = false

# Normally this is 31, but this gives us 2 weeks of additional testing.
academic_year_number_of_preparation_days = 45

http_hosts = {
  MAVIS__HOST                        = "qa.mavistesting.com"
  MAVIS__GIVE_OR_REFUSE_CONSENT_HOST = "qa.mavistesting.com"
}
appspec_bucket            = "nhse-mavis-appspec-bucket-qa"
minimum_web_replicas      = 2
maximum_web_replicas      = 4
max_aurora_capacity_units = 16
container_insights        = "enhanced"

enable_backup_to_vault = true
