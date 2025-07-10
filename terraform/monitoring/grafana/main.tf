terraform {
  required_version = "~> 1.11.4"
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 3.25.4"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.2"
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

provider "aws" {
  region = "us-east-1"
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
