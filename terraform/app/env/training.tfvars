environment = "training"
dns_certificate_arn = [
  "arn:aws:acm:eu-west-2:393416225559:certificate/368edbcb-37c5-4146-9087-ff011bef5e05",
  "arn:aws:acm:eu-west-2:393416225559:certificate/e93e3912-eee4-4f6e-826d-c628bff58527",
]
docker_image = "mavis/webapp"
resource_name = {
  rds_security_group       = "mavis-training-AddonsStack-1JZSXP7P84221-dbDBClusterSecurityGroup-A5NL1GFJ83LX"
  loadbalancer             = "mavis--Publi-w1wzc4E2jrl6"
  lb_security_group        = "mavis-training-PublicHTTPLoadBalancerSecurityGroup-L8GOGS04ARYI"
  cloudwatch_vpc_log_group = "mavis-training-FlowLogs"
}
rails_env             = "staging"
rails_master_key_path = "/copilot/mavis/secrets/STAGING_RAILS_MASTER_KEY"

enable_splunk                   = false
enable_cis2                     = false
enable_pds_enqueue_bulk_updates = false

http_hosts = {
  MAVIS__HOST                        = "training.manage-vaccinations-in-schools.nhs.uk"
  MAVIS__GIVE_OR_REFUSE_CONSENT_HOST = "training.give-or-refuse-consent-for-vaccinations.nhs.uk"
}
appspec_bucket       = "nhse-mavis-appspec-bucket-training"
minimum_web_replicas = 2
maximum_web_replicas = 4
