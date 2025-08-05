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
    resources = ["*"] #TODO: Restrict permissions to only Mavis-specifc resources
    effect    = "Allow"
  }
  statement {
    actions   = ["s3:GetObject", "s3:GetObjectVersion"]
    resources = ["arn:aws:s3:::*"]
    effect    = "Allow"
  }
  statement {
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.ecs_task_role.arn, aws_iam_role.ecs_task_execution_role.arn]
    effect    = "Allow"
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
  statement {
    sid     = "railsKeySid"
    actions = ["ssm:GetParameters"]
    resources = concat([
      "arn:aws:ssm:${var.region}:${var.account_id}:parameter${var.rails_master_key_path}"
    ], local.parameter_store_arns)
    effect = "Allow"
  }
  statement {
    sid     = "dbSecretSid"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      aws_rds_cluster.core.master_user_secret[0].secret_arn
    ]
    effect = "Allow"
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
