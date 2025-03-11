environment   = "training"
db_secret_arn = "arn:aws:secretsmanager:eu-west-2:393416225559:secret:dbAuroraSecret-3bG6y4wn5Enz-YvireA"
dns_certificate_arn = [
  "arn:aws:acm:eu-west-2:393416225559:certificate/6225e0bb-7365-4dce-9cad-4112b1e3fcc0",
  "arn:aws:acm:eu-west-2:393416225559:certificate/0ee8635d-d358-46fc-96d7-0288413dbc0e",
]
enable_autoscaling = false
docker_image       = "mavis/webapp"
resource_name = {
  dbsubnet_group           = "mavis-training-addonsstack-1jzsxp7p84221-dbdbsubnetgroup-ybdt5wfbx9jl"
  db_cluster               = "mavis-training-addonsstack-1jzsxp7p842-dbdbcluster-dojxjwailzmh"
  db_instance              = "mavis-training-addonsstack-1jzs-dbdbwriterinstance-pbl8rjktgtmp"
  rds_security_group       = "mavis-training-AddonsStack-1JZSXP7P84221-dbDBClusterSecurityGroup-A5NL1GFJ83LX"
  loadbalancer             = "mavis--Publi-w1wzc4E2jrl6"
  lb_security_group        = "mavis-training-PublicHTTPLoadBalancerSecurityGroup-L8GOGS04ARYI"
  cloudwatch_vpc_log_group = "mavis-training-FlowLogs"
}
rails_env             = "staging"
rails_master_key_path = "/copilot/mavis/secrets/STAGING_RAILS_MASTER_KEY"
splunk_enabled        = "false"
cis2_enabled          = "false"
pds_enabled           = "false"
http_hosts = {
  MAVIS__HOST                        = "training.manage-vaccinations-in-schools.nhs.uk"
  MAVIS__GIVE_OR_REFUSE_CONSENT_HOST = "training.manage-vaccinations-in-schools.nhs.uk"
}
minimum_replicas = 3
