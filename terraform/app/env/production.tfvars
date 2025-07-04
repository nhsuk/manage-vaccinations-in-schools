environment         = "production"
dns_certificate_arn = ["arn:aws:acm:eu-west-2:820242920762:certificate/dd00edc0-b305-45bd-83aa-7c7f298b0a68"]
docker_image        = "mavis/webapp"
resource_name = {
  rds_security_group       = "mavis-production-AddonsStack-H6B1986BQ928-dbDBClusterSecurityGroup-dEt2cEtcHBMo"
  loadbalancer             = "mavis-production-pub-lb"
  lb_security_group        = "mavis-production-PublicHTTPLoadBalancerSecurityGroup-G7umbZTkvkwK"
  cloudwatch_vpc_log_group = "mavis-production-FlowLogs"
}
rails_env             = "production"
rails_master_key_path = "/copilot/mavis/production/secrets/RAILS_MASTER_KEY"

http_hosts = {
  MAVIS__HOST                        = "www.manage-vaccinations-in-schools.nhs.uk"
  MAVIS__GIVE_OR_REFUSE_CONSENT_HOST = "www.give-or-refuse-consent-for-vaccinations.nhs.uk"
}

appspec_bucket            = "nhse-mavis-appspec-bucket-production"
account_id                = 820242920762
vpc_log_retention_days    = 14
ecs_log_retention_days    = 30
backup_retention_period   = 7
ssl_policy                = "ELBSecurityPolicy-TLS13-1-2-2021-06"
access_logs_bucket        = "nhse-mavis-access-logs-production"
max_aurora_capacity_units = 16
minimum_web_replicas      = 2
maximum_web_replicas      = 4
container_insights        = "enhanced"

enable_backup_to_vault = true
