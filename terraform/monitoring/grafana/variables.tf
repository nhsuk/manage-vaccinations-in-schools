variable "service_account_token" {
  type        = string
  description = "Service account token for Grafana workspace."
  nullable    = false
}

variable "workspace_url" {
  type        = string
  description = "URL of the Grafana workspace."
  nullable    = false
}

variable "dns_hosted_zone" {
  type        = string
  description = "DNS hosted zone for custom DNS record for Grafana workspace."
  default     = ""
  nullable    = false
}

variable "region" {
  type        = string
  default     = "eu-west-2"
  description = "AWS region for the Grafana workspace."
}
