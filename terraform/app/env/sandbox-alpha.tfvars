environment           = "sandbox-alpha"
rails_master_key_path = "/copilot/mavis/secrets/STAGING_RAILS_MASTER_KEY"
dns_certificate_arn   = null
resource_name = {
  rds_security_group       = "mavis-sandbox-alpha-rds-sg"
  loadbalancer             = "mavis-sandbox-alpha-alb"
  lb_security_group        = "mavis-sandbox-alpha-alb-sg"
  cloudwatch_vpc_log_group = "mavis-sandbox-alpha-FlowLogs"
}
http_hosts = {
  MAVIS__HOST                        = "sandbox-alpha.mavistesting.com"
  MAVIS__GIVE_OR_REFUSE_CONSENT_HOST = "sandbox-alpha.mavistesting.com"
}

enable_splunk                   = false
enable_cis2                     = false
enable_pds_enqueue_bulk_updates = false

appspec_bucket       = "nhse-mavis-appspec-bucket-sandbox-alpha"
minimum_web_replicas = 1
maximum_web_replicas = 2
good_job_replicas    = 1
