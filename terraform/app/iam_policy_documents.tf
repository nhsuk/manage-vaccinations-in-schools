# These data objects do not attach to any AWS sources, instead they simply generate a local resource which can be used
# to generate the JSON policy document for aws IAM in a terraform-friendly manner with less boiler-plate

data "aws_iam_policy_document" "ecs_monitoring" {
  statement {
    actions = [
      "logs:CreateLogGroup",
    ]
    resources = ["*"]
    effect    = "Allow"
  }
}

data "aws_iam_policy_document" "ecs_secrets_access" {
  for_each = local.applications_accessing_secrets_or_parameters
  dynamic "statement" {
    for_each = length(local.parameter_values[each.key]) == 0 ? [] : [1]
    content {
      sid     = "ssmParameterStoreAccessSid"
      actions = ["ssm:GetParameters"]
      resources = concat(
        [for kv_pair in local.parameter_values[each.key] : kv_pair["valueFrom"]],
        [aws_ssm_parameter.prometheus_config.arn, aws_ssm_parameter.cloudwatch_agent_config.arn]
      )
      effect = "Allow"
    }
  }
  dynamic "statement" {
    for_each = length(local.secret_values[each.key]) == 0 ? [] : [1]
    content {
      sid       = "dbSecretSid"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = [for kv_pair in local.secret_values[each.key] : kv_pair["valueFrom"]]
      effect    = "Allow"
    }
  }
}

data "aws_iam_policy_document" "vpc_flowlogs" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]
    resources = ["*"] # TODO restrict this to aws_cloudwatch_log_group.vpc_log_group
    effect    = "Allow"
  }
}
