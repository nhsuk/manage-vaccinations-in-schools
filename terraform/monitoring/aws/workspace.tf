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
  vpc_configuration {
    security_group_ids = [aws_security_group.grafana_workspace.id]
    subnet_ids         = data.aws_subnets.data_replication.ids
  }
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

resource "aws_security_group" "grafana_workspace" {
  name_prefix = "grafana-workspace-${var.environment}"
  description = "Security group for Grafana workspace"
  vpc_id      = data.aws_vpcs.data_replication.ids[0]
  tags = {
    Name = "grafana-workspace-sg-${var.environment}"
  }
}

resource "aws_security_group_rule" "egress_rds" {
  type              = "egress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  security_group_id = aws_security_group.grafana_workspace.id
  cidr_blocks       = ["10.0.0.0/16"]
}

resource "aws_security_group_rule" "egress_443" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.grafana_workspace.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ingress_443" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.grafana_workspace.id
  cidr_blocks       = ["0.0.0.0/0"]
}

data "aws_vpcs" "data_replication" {
  filter {
    name   = "tag:Environment"
    values = [local.data_replication_prefix]
  }
}

data "aws_subnets" "data_replication" {
  filter {
    name   = "vpc-id"
    values = data.aws_vpcs.data_replication.ids
  }
  filter {
    name   = "tag:Private"
    values = [true]
  }
}
