environment   = "training"
db_secret_arn = ""
dns_certificate_arn = [
  "arn:aws:acm:eu-west-2:393416225559:certificate/6225e0bb-7365-4dce-9cad-4112b1e3fcc0",
  "arn:aws:acm:eu-west-2:393416225559:certificate/0ee8635d-d358-46fc-96d7-0288413dbc0e",
]
enable_autoscaling = false
docker_image       = "mavis/webapp"
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
rails_master_key_path = "/copilot/mavis/training/secrets/RAILS_MASTER_KEY"
splunk_enabled        = "false"
cis2_enabled          = "false"
pds_enabled           = "false"
http_hosts = {
  MAVIS__HOST                        = "training.manage-vaccinations-in-schools.nhs.uk"
  MAVIS__GIVE_OR_REFUSE_CONSENT_HOST = "training.manage-vaccinations-in-schools.nhs.uk"
}
minimum_replicas = 3
