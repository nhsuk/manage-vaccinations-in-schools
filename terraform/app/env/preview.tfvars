environment         = "preview"
db_secret_arn       = ""
dns_certificate_arn = null
enable_autoscaling  = false
docker_image        = "mavis/webapp"
resource_name = {
  dbsubnet_group           = ""
  db_cluster               = ""
  db_instance              = ""
  rds_security_group       = ""
  loadbalancer             = ""
  lb_security_group        = ""
  cloudwatch_vpc_log_group = ""
}
rails_env             = "staging"
rails_master_key_path = "/copilot/mavis/preview/secrets/RAILS_MASTER_KEY"
splunk_enabled        = "false"
cis2_enabled          = "false"
pds_enabled           = "false"
http_hosts = {
  MAVIS__HOST                        = "preview.mavistesting.com"
  MAVIS__GIVE_OR_REFUSE_CONSENT_HOST = "preview.mavistesting.com"
}

minimum_replicas = 3
