environment           = "sandbox-beta"
rails_master_key_path = "/copilot/mavis/secrets/STAGING_RAILS_MASTER_KEY"
db_secret_arn         = null
dns_certificate_arn   = null
resource_name = {
  dbsubnet_group           = "mavis-sandbox-beta-rds-subnet"
  db_cluster               = "mavis-sandbox-beta-rds-cluster"
  db_instance              = "mavis-sandbox-beta-rds-instance"
  rds_security_group       = "mavis-sandbox-beta-rds-sg"
  loadbalancer             = "mavis-sandbox-beta-alb"
  lb_security_group        = "mavis-sandbox-beta-alb-sg"
  cloudwatch_vpc_log_group = "mavis-sandbox-beta-FlowLogs"
}
http_hosts = {
  MAVIS__HOST                        = "sandbox-beta.mavistesting.com"
  MAVIS__GIVE_OR_REFUSE_CONSENT_HOST = "sandbox-beta.mavistesting.com"
}

enable_splunk                   = false
enable_cis2                     = false
enable_pds_enqueue_bulk_updates = false

minimum_web_replicas = 2
appspec_bucket       = "nhse-mavis-appspec-bucket-sandbox-beta"
