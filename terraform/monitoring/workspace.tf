resource "aws_grafana_workspace" "this" {
  name                     = "grafana-${var.environment}"
  description              = "Grafana workspace for ${var.environment} environment"
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["SAML", "AWS_SSO"]
  permission_type          = "SERVICE_MANAGED"
  role_arn                 = aws_iam_role.grafana.arn
  configuration = jsonencode({
    unifiedAlerting = {
      enabled = true
    }
    plugins = {
      pluginAdminEnabled = true
    }
  })
  data_sources = ["CLOUDWATCH"]
}

resource "aws_grafana_role_association" "grafana_admin" {
  workspace_id = aws_grafana_workspace.this.id
  role         = "ADMIN"
  group_ids    = [local.group_ids["AWS-Mavis-Admins"]]
}

resource "aws_grafana_role_association" "grafana_editor" {
  workspace_id = aws_grafana_workspace.this.id
  role         = "EDITOR"
  group_ids    = [local.group_ids["AWS-Mavis-Developers"]]
}

resource "aws_grafana_role_association" "grafana_viewer" {
  workspace_id = aws_grafana_workspace.this.id
  role         = "VIEWER"
  group_ids    = [local.group_ids["AWS-Mavis-ReadOnly"]]
}

resource "aws_grafana_workspace_service_account" "grafana_provider" {
  name         = "grafana-provider-admin"
  grafana_role = "ADMIN"
  workspace_id = aws_grafana_workspace.this.id
}
