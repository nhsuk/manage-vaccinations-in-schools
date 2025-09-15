# These data objects do not attach to any AWS sources, instead they simply generate a local resource which can be used
# to generate the JSON policy document for aws IAM in a terraform-friendly manner with less boiler-plate
data "aws_iam_policy_document" "codedeploy" {
  statement {
    actions   = ["ecs:DescribeServices", "ecs:UpdateServicePrimaryTaskSet"]
    resources = [module.web_service.service.id]
    effect    = "Allow"
  }
  statement {
    actions   = ["ecs:CreateTaskSet", "ecs:DeleteTaskSet"]
    resources = ["arn:aws:ecs:*:*:task-set/${aws_ecs_cluster.cluster.name}/${module.web_service.service.name}/*"]
    effect    = "Allow"
  }
  statement {
    actions = [
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:ModifyRule"
    ]
    resources = ["*"]
    effect    = "Allow"
  }
  statement {
    actions = ["iam:PassRole"]
    resources = concat(
      [aws_iam_role.ecs_task_role.arn],
      [for role in aws_iam_role.ecs_task_execution_role : role.arn]
    )
    effect = "Allow"
  }
}

data "aws_iam_policy_document" "shell_access" {
  statement {
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = ["*"]
    effect    = "Allow"
  }
}

data "aws_iam_policy_document" "ecs_secrets_access" {
  for_each = local.non_empty_parameter_groups
  dynamic "statement" {
    for_each = length(local.parameter_store_paths[each.key]) == 0 ? [] : [1]
    content {
      sid       = "ssmParameterStoreAccessSid"
      actions   = ["ssm:GetParameters"]
      resources = [for path in local.parameter_store_paths[each.key] : "arn:aws:ssm:${var.region}:${var.account_id}:parameter${path}"]
      effect    = "Allow"
    }
  }
  dynamic "statement" {
    for_each = length(local.secret_arns[each.key]) == 0 ? [] : [1]
    content {
      sid       = "dbSecretSid"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = local.secret_arns[each.key]
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
