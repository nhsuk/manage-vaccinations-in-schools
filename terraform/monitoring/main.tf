terraform {
  required_version = "~> 1.11.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.87"
    }

    grafana = {
      source  = "grafana/grafana"
      version = "~> 3.25.4"
    }
  }

  backend "s3" {
    region       = "eu-west-2"
    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region = "eu-west-2"
}

provider "grafana" {
  url  = aws_grafana_workspace.this.endpoint
  auth = aws_grafana_workspace_service_account_token.grafana_provider_key.key
}
