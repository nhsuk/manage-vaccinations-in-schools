################################# IAM Policies #################################
resource "aws_iam_policy" "ecs_secret_access_policy" {
  for_each = local.applications_accessing_secrets_or_parameters
  name     = "ecs-secret-access-policy-${var.environment}-${each.key}"
  policy   = data.aws_iam_policy_document.ecs_secrets_access[each.key].json
}

resource "aws_iam_policy" "shell_access_policy" {
  name   = "ECSFargateAllowExecuteCommand-${var.environment}"
  policy = data.aws_iam_policy_document.shell_access.json
}

resource "aws_iam_policy" "vpc_flowlogs" {
  name   = "vpc-flowlogs-${var.environment}"
  policy = data.aws_iam_policy_document.vpc_flowlogs.json
}

################################# IAM Roles #################################


resource "aws_iam_role" "ecs_task_execution_role" {
  for_each           = local.parameter_store_variables
  name               = "ecsTaskExecutionRole-${var.environment}-${each.key}"
  assume_role_policy = templatefile("templates/iam_assume_role.json.tpl", { service_name = "ecs-tasks.amazonaws.com" })
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "ecsTaskRole-${var.environment}"
  assume_role_policy = templatefile("templates/iam_assume_role.json.tpl", { service_name = "ecs-tasks.amazonaws.com" })
}

resource "aws_iam_role" "ecs_deploy" {
  name               = "ecs-deploy-${var.environment}"
  assume_role_policy = templatefile("templates/iam_assume_role.json.tpl", { service_name = "ecs.amazonaws.com" })
}

resource "aws_iam_role" "vpc_flowlogs" {
  name = "vpcFlowLogsRole-${var.environment}"
  assume_role_policy = templatefile("templates/iam_assume_role.json.tpl", {
    service_name = "vpc-flow-logs.amazonaws.com"
  })
}

################################# IAM Role/Policy Attachments #################################

resource "aws_iam_role_policy_attachment" "ecs_secret_access" {
  for_each   = local.applications_accessing_secrets_or_parameters
  role       = aws_iam_role.ecs_task_execution_role[each.key].name
  policy_arn = aws_iam_policy.ecs_secret_access_policy[each.key].arn
}

resource "aws_iam_role_policy_attachment" "ecs_ecr_and_log_permissions" {
  for_each   = local.parameter_store_variables
  role       = aws_iam_role.ecs_task_execution_role[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_fargate" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.shell_access_policy.arn
}

resource "aws_iam_role_policy_attachment" "ecs_deploy" {
  role       = aws_iam_role.ecs_deploy.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECSInfrastructureRolePolicyForLoadBalancers"
}


resource "aws_iam_role_policy_attachment" "vpc_create_logs" {
  role       = aws_iam_role.vpc_flowlogs.name
  policy_arn = aws_iam_policy.vpc_flowlogs.arn
}
