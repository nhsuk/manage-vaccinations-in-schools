resource "aws_grafana_workspace" "this" {
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["SAML", "AWS_SSO"]
  permission_type          = "SERVICE_MANAGED"
  role_arn                 = aws_iam_role.assume.arn
  configuration = jsonencode({
    unifiedAlerting = {
      enabled = true
    }
    plugins = {
      pluginAdminEnabled = true
    }
  })
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
