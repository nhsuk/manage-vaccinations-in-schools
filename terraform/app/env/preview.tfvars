environment         = "preview"
db_secret_arn       = "arn:aws:secretsmanager:eu-west-2:393416225559:secret:dbAuroraSecret-ysKvF5RMbWMr-lnpooZ"
dns_certificate_arn = null
enable_autoscaling  = false
docker_image        = "mavis/webapp"
resource_name = {
  dbsubnet_group           = "mavis-preview-addonsstack-1pd6pksn106rk-dbdbsubnetgroup-8pkydanicgra"
  db_cluster               = "mavis-preview-addonsstack-1pd6pksn106r-dbdbcluster-lrf8p5py9wfb"
  db_instance              = "mavis-preview-addonsstack-1pd6p-dbdbwriterinstance-aozmqfwfm2va"
  rds_security_group       = "mavis-preview-AddonsStack-1PD6PKSN106RK-dbDBClusterSecurityGroup-7cmoQwi6uv8e"
  loadbalancer             = "mavis-preview-pub-lb"
  lb_security_group        = "mavis-preview-PublicHTTPLoadBalancerSecurityGroup-qfHAKWH39OY3"
  cloudwatch_vpc_log_group = "mavis-preview-FlowLogs"
}
rails_env             = "staging"
rails_master_key_path = "/copilot/mavis/secrets/STAGING_RAILS_MASTER_KEY"
splunk_enabled        = "false"
cis2_enabled          = "false"
pds_enabled           = "false"
http_hosts = {
  MAVIS__HOST                        = "preview.mavistesting.com"
  MAVIS__GIVE_OR_REFUSE_CONSENT_HOST = "preview.mavistesting.com"
}

minimum_replicas           = 3
appspec_bucket             = "nhse-mavis-appspec-bucket-preview"
background_service_enabled = true
