terraform {
  required_version = "~> 1.13.3"
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 4.8.0"
    }
  }

  backend "s3" {
    region       = "eu-west-2"
    use_lockfile = true
    encrypt      = true
  }
}

provider "grafana" {
  url  = var.workspace_url
  auth = var.service_account_token
}

resource "grafana_data_source" "cloudwatch" {
  name = "CloudWatch"
  type = "cloudwatch"
  json_data_encoded = jsonencode({
    authType      = "default"
    defaultRegion = var.region
  })
  uid = "cloudwatch"
}

resource "grafana_folder" "ecs" {
  title = "ECS"
  uid   = "ecs-folder"
}

resource "grafana_folder" "database" {
  title = "Database"
  uid   = "database-folder"
}

resource "grafana_folder" "load_balancer" {
  title = "Load Balancer"
  uid   = "load-balancer-folder"
}

resource "grafana_contact_point" "slack" {
  name = "Slack"

  slack {
    url = var.slack_webhook_url
  }

  lifecycle {
    ignore_changes = [slack]
  }
}

resource "grafana_notification_policy" "slack" {
  contact_point = grafana_contact_point.slack.name
  group_by      = ["grafana_folder", "alertname"]
}

# Add the alert modules to create alerting rules from the stored configurations
module "development_alerts" {
  source = "./modules/development_alerts"
  count  = var.environment == "development" ? 1 : 0
}

module "production_alerts" {
  source = "./modules/production_alerts"
  count  = var.environment == "production" ? 0 : 0
}
