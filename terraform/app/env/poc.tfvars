environment_string  = "poc"
db_secret_arn       = ""
dns_certificate_arn = ""
resource_name = {
  dbsubnet_group           = "mavis-poc-rds-subnet"
  db_cluster               = "mavis-poc-rds-cluster"
  rds_security_group       = "mavis-poc-rds-sg"
  loadbalancer             = "mavis-poc-alb"
  lb_security_group        = "mavis-poc-alb-sg"
  cloudwatch_vpc_log_group = "mavis-poc-FlowLogs"
}
image_tag             = "latest"
rails_env             = "staging"
rails_master_key_path = "/copilot/mavis/copilotmigration/secrets/RAILS_MASTER_KEY"
