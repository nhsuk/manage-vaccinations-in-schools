environment = "copilotmigration"
rails_master_key_path = "/copilot/mavis/secrets/STAGING_RAILS_MASTER_KEY"
db_secret_arn       = "arn:aws:secretsmanager:eu-west-2:393416225559:secret:dbAuroraSecret-zdVWVjrfgplI-7RGaPm"
dns_certificate_arn = ["arn:aws:acm:eu-west-2:393416225559:certificate/2936cd40-34df-40b9-a902-f77be4edb05e"]
resource_name = {
  dbsubnet_group           = "mavis-copilotmigration-addonsstack-an4d9pidj1qd-dbdbsubnetgroup-il53a9jq9xg1"
  db_cluster               = "mavis-copilotmigration-addonsstack-an4-dbdbcluster-jrv5mrfo45rl"
  db_instance              = "mavis-copilotmigration-addonsst-dbdbwriterinstance-hagvyoaflqjr"
  rds_security_group       = "mavis-copilotmigration-AddonsStack-AN4D9PIDJ1QD-dbDBClusterSecurityGroup-OmiC6wgtxUZ6"
  loadbalancer             = "mavis-copilotmigration-pub-lb"
  lb_security_group        = "mavis-copilotmigration-PublicHTTPLoadBalancerSecurityGroup-bmSxgvij8tPU"
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
