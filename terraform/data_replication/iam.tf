data "aws_iam_policy_document" "ecs_permissions" {
  statement {
    sid     = "railsKeySid"
    actions = ["ssm:GetParameters"]
    resources = [
      "arn:aws:ssm:${var.region}:${var.account_id}:parameter${var.rails_master_key_path}"
    ]
    effect = "Allow"
  }
  statement {
    sid     = "dbSecretSid"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      var.db_secret_arn
    ]
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

resource "aws_iam_policy" "ecs_permissions" {
  name   = "${local.name_prefix}-ecs-permissions"
  policy = data.aws_iam_policy_document.ecs_permissions.json
}

resource "aws_iam_policy" "shell_access_policy" {
  name   = "${local.name_prefix}-ecs-shell-access"
  policy = data.aws_iam_policy_document.shell_access.json
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${local.name_prefix}-ecsTaskExecutionRole"
  assume_role_policy = templatefile("../app/templates/iam_assume_role.json.tpl", { service_name = "ecs-tasks.amazonaws.com" })
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "${local.name_prefix}-ecsTaskRole"
  assume_role_policy = templatefile("../app/templates/iam_assume_role.json.tpl", { service_name = "ecs-tasks.amazonaws.com" })
}

resource "aws_iam_role_policy_attachment" "ecs_permissinos" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_permissions.arn
}

resource "aws_iam_role_policy_attachment" "ecs_ecr_and_log_permissions" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_fargate" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.shell_access_policy.arn
}
