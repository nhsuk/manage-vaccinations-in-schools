terraform {
  required_version = "~> 1.13.3"
  required_providers {
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

resource "grafana_data_source" "postgresql" {
  name = "postgresql"
  type = "grafana-postgresql-datasource"
  json_data_encoded = jsonencode({
    sslmode                = "require"
    connMaxLifetime        = 14400
    database               = "manage_vaccinations"
    maxIdleConns           = 5
    maxIdleConnsAuto       = true
    maxOpenConns           = 5
    tlsConfigurationMethod = "file-path"
    timescaledb            = false
    postgresVersion        = 1500
  })
  secure_json_data_encoded = jsonencode({
    password = "CHANGE_ME"
  })
  url      = "CHANGE_ME"
  uid      = "postgres"
  username = "grafana_ro"
  lifecycle {
    ignore_changes = [
      secure_json_data_encoded,
      url,
    ]
  }
}
