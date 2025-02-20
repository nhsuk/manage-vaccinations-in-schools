environment = "copilotmigration"
db_secret_arn       = null
dns_certificate_arn = null
enable_autoscaling = false
docker_image       = "mavis/webapp"

resource_name = {
  dbsubnet_group           = ""
  db_cluster               = ""
  rds_security_group       = ""
  loadbalancer             = "mavis-copilotmigration-pub-lb"
  lb_security_group        = ""
  cloudwatch_vpc_log_group = "mavis-copilotmigration-FlowLogs"
}

rails_master_key_path = "/copilot/mavis/copilotmigration/secrets/RAILS_MASTER_KEY"

rails_env = "staging"

splunk_enabled = "true"
cis2_enabled   = "true"
pds_enabled    = "true"
