environment = "copilotmigration"
rails_master_key_path = "/copilot/mavis/secrets/STAGING_RAILS_MASTER_KEY"
db_secret_arn       = null
dns_certificate_arn = null
resource_name = {
  dbsubnet_group           = "mavis-copilotmigration-rds-subnet"
  db_cluster               = "mavis-copilotmigration-rds-cluster"
  db_instance              = "mavis-copilotmigration-rds-instance"
  rds_security_group       = "mavis-copilotmigration-rds-sg"
  loadbalancer             = "mavis-copilotmigration-alb"
  lb_security_group        = "mavis-copilotmigration-alb-sg"
  cloudwatch_vpc_log_group = "mavis-copilotmigration-FlowLogs"
}
http_hosts = {
  MAVIS__HOST                        = "copilotmigration.mavistesting.com"
  MAVIS__GIVE_OR_REFUSE_CONSENT_HOST = "copilotmigration.mavistesting.com"
}
splunk_enabled = "false"
cis2_enabled   = "false"
pds_enabled    = "false"
minimum_replicas = 3
appspec_bucket = "nhse-mavis-appspec-bucket-copilotmigration"
enable_autoscaling = "true"
