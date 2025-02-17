################################# IAM Policies #################################
resource "aws_iam_policy" "ecs_secret_access_policy" {
  name   = "ecs-secret-access-policy-${var.environment}"
  policy = data.aws_iam_policy_document.ecs_secrets_access.json
}

resource "aws_iam_policy" "shell_access_policy" {
  name   = "ECSFargateAllowExecuteCommand-${var.environment}"
  policy = data.aws_iam_policy_document.shell_access.json
}

resource "aws_iam_policy" "codedeploy_restricted" {
  name   = "codedeploy-restricted-${var.environment}"
  policy = data.aws_iam_policy_document.codedeploy.json
}

resource "aws_iam_policy" "vpc_flowlogs" {
  name   = "vpc-flowlogs-${var.environment}"
  policy = data.aws_iam_policy_document.vpc_flowlogs.json
}

################################# IAM Roles #################################


resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecsTaskExecutionRole-${var.environment}"
  assume_role_policy = templatefile("templates/iam_assume_role.json.tpl", { service_name = "ecs-tasks.amazonaws.com" })
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "ecsTaskRole-${var.environment}"
  assume_role_policy = templatefile("templates/iam_assume_role.json.tpl", { service_name = "ecs-tasks.amazonaws.com" })
}

resource "aws_iam_role" "code_deploy" {
  name               = "codeDeployRole-${var.environment}"
  assume_role_policy = templatefile("templates/iam_assume_role.json.tpl", { service_name = "codedeploy.amazonaws.com" })
}

resource "aws_iam_role" "vpc_flowlogs" {
  name = "vpcFlowLogsRole-${var.environment}"
  assume_role_policy = templatefile("templates/iam_assume_role.json.tpl", {
    service_name = "vpc-flow-logs.amazonaws.com"
  })
}

################################# IAM Role/Policy Attachments #################################

resource "aws_iam_role_policy_attachment" "ecs_secret_access" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_secret_access_policy.arn
}

resource "aws_iam_role_policy_attachment" "ecs_ecr_and_log_permissions" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_fargate" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.shell_access_policy.arn
}

resource "aws_iam_role_policy_attachment" "code_deploy_blue_green" {
  role       = aws_iam_role.code_deploy.name
  policy_arn = aws_iam_policy.codedeploy_restricted.arn
}


resource "aws_iam_role_policy_attachment" "vpc_create_logs" {
  role       = aws_iam_role.vpc_flowlogs.name
  policy_arn = aws_iam_policy.vpc_flowlogs.arn
}
