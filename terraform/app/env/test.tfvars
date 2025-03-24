environment         = "test"
db_secret_arn       = "arn:aws:secretsmanager:eu-west-2:393416225559:secret:dbAuroraSecret-LwdZBGzdPMq6-PkAjKC"
dns_certificate_arn = ["arn:aws:acm:eu-west-2:393416225559:certificate/7e80f006-e9d8-488f-b950-d97f3cc41e4f"]
enable_autoscaling  = false
docker_image        = "mavis/webapp"
resource_name = {
  dbsubnet_group           = "mavis-test-addonsstack-gb8z9lqvo8of-dbdbsubnetgroup-8hrfkmuyp4c4"
  db_cluster               = "mavis-test-addonsstack-gb8z9lqvo8of-dbdbcluster-0ed2hxoxu1v1"
  db_instance              = "mavis-test-addonsstack-gb8z9lqv-dbdbwriterinstance-mq40ycdtxcan"
  rds_security_group       = "mavis-test-AddonsStack-GB8Z9LQVO8OF-dbDBClusterSecurityGroup-1KSO3O1CL4NI5"
  loadbalancer             = "mavis--Publi-W19xy2QLULZ4"
  lb_security_group        = "mavis-test-PublicHTTPLoadBalancerSecurityGroup-15LE48D6JYPML"
  cloudwatch_vpc_log_group = "mavis-test-FlowLogs"
}
rails_env             = "staging"
rails_master_key_path = "/copilot/mavis/secrets/STAGING_RAILS_MASTER_KEY"
splunk_enabled        = "true"
cis2_enabled          = "true"
pds_enabled           = "true"
http_hosts = {
  MAVIS__HOST                        = "test.mavistesting.com"
  MAVIS__GIVE_OR_REFUSE_CONSENT_HOST = "test.mavistesting.com"
}
minimum_replicas = 3
appspec_bucket = "nhse-mavis-appspec-bucket-test"
