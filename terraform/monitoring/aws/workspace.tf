resource "aws_grafana_workspace" "this" {
  name                     = "grafana-${var.environment}"
  description              = "Grafana workspace for ${var.environment} environment"
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["AWS_SSO"]
  permission_type          = "CUSTOMER_MANAGED"
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

resource "aws_grafana_role_association" "role" {
  for_each     = local.group_ids
  workspace_id = aws_grafana_workspace.this.id
  role         = each.key
  group_ids    = values(merge(each.value, lookup(var.sso_group_ids, each.key, {})))
}

resource "aws_grafana_workspace_service_account" "grafana_provider" {
  name         = "grafana-provider-admin"
  grafana_role = "ADMIN"
  workspace_id = aws_grafana_workspace.this.id
}
