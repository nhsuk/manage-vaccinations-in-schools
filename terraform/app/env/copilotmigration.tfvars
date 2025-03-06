environment = "copilotmigration"
db_secret_arn       = "arn:aws:secretsmanager:eu-west-2:393416225559:secret:dbAuroraSecret-t7WsT4gxwQDz-LpQLQg"
dns_certificate_arn = "arn:aws:acm:eu-west-2:393416225559:certificate/2936cd40-34df-40b9-a902-f77be4edb05e"
enable_autoscaling = false
docker_image       = "mavis/webapp"

resource_name = {
  dbsubnet_group           = "mavis-copilotmigration-addonsstack-1g1buclosh22s-dbdbsubnetgroup-bob2xepawvic"
  db_cluster               = "mavis-copilotmigration-addonsstack-1g1-dbdbcluster-hhag0c0l90rb"
  db_instance              = "tf-20250225163322733000000001"
  rds_security_group       = "mavis-copilotmigration-AddonsStack-1G1BUCLOSH22S-dbDBClusterSecurityGroup-nCJ5DRyjNeMI"
  loadbalancer             = "mavis-copilotmigration-pub-lb"
  lb_security_group        = "mavis-copilotmigration-PublicHTTPLoadBalancerSecurityGroup-IZesKSNYalJs"
  cloudwatch_vpc_log_group = "mavis-copilotmigration-FlowLogs"
}

rails_master_key_path = "/copilot/mavis/copilotmigration/secrets/RAILS_MASTER_KEY"

rails_env = "staging"

splunk_enabled = "true"
cis2_enabled   = "false"
pds_enabled    = "false"
http_hosts = {
  MAVIS__HOST                        = "copilotmigration.mavistesting.com"
  MAVIS__GIVE_OR_REFUSE_CONSENT_HOST = "copilotmigration.mavistesting.com"
}
