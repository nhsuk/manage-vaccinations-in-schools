environment         = "qa"
db_secret_arn       = "arn:aws:secretsmanager:eu-west-2:393416225559:secret:dbAuroraSecret-GBwVtQEAmugK-wPubjU"
dns_certificate_arn = null
enable_autoscaling  = false
docker_image        = "mavis/webapp"
resource_name = {
  dbsubnet_group           = "mavis-qa-addonsstack-z0l4gx5euv3i-dbdbsubnetgroup-fgvafc16exxw"
  db_cluster               = "mavis-qa-addonsstack-z0l4gx5euv3i-dbdbcluster-ysszxsdiq1ka"
  db_instance              = "mavis-qa-addonsstack-z0l4gx5euv-dbdbwriterinstance-sstfvcbqdcwa"
  rds_security_group       = "mavis-qa-AddonsStack-Z0L4GX5EUV3I-dbDBClusterSecurityGroup-vd2Avaw4JIgr"
  loadbalancer             = "mavis-qa-pub-lb"
  lb_security_group        = "mavis-qa-PublicHTTPSLoadBalancerSecurityGroup-9gnrzuf6bRE4"
  cloudwatch_vpc_log_group = "mavis-qa-FlowLogs"
}
rails_env             = "staging"
rails_master_key_path = "/copilot/mavis/secrets/STAGING_RAILS_MASTER_KEY"
splunk_enabled        = "false"
cis2_enabled          = "false"
pds_enabled           = "false"
http_hosts = {
  MAVIS__HOST                        = "qa.mavistesting.com"
  MAVIS__GIVE_OR_REFUSE_CONSENT_HOST = "qa.mavistesting.com"
}
minimum_replicas = 3
