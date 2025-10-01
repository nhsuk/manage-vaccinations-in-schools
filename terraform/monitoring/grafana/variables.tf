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

variable "region" {
  type        = string
  default     = "eu-west-2"
  description = "AWS region for the Grafana workspace."
}

variable "environment" {
  type        = string
  description = "Determines which alerting configuration to use (development or production)."
  nullable    = false
}

variable "slack_webhook_url" {
  type        = string
  description = "Slack webhook URL for sending alerts."
  nullable    = false
}
