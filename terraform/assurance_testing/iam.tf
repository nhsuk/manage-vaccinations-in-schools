################################# IAM Roles #################################
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "EcsTaskExecutionRole-${var.identifier}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role" "ecs_task_role" {
  name = "EcsTaskRole-${var.identifier}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}


################################# IAM Policies #################################

data "aws_iam_policy_document" "additional_task_execution_permissions" {
  statement {
    actions = [
      "logs:CreateLogGroup"
    ]
    resources = ["*"]
    effect    = "Allow"
  }
  statement {
    effect    = "Allow"
    resources = ["arn:aws:secretsmanager:eu-west-2:393416225559:secret:performancetest/auth-token-e8yMWw"]
    actions = [
      "secretsmanager:GetSecretValue",
    ]
  }
}

resource "aws_iam_policy" "additional_task_execution_permissions" {
  name   = "${var.identifier}-task-execution-permissions"
  policy = data.aws_iam_policy_document.additional_task_execution_permissions.json
}

data "aws_iam_policy_document" "additional_task_permissions" {
  statement {
    actions = [
      "s3:ListBucket",
    ]
    resources = [module.s3_performance_reports.arn]
    effect    = "Allow"
  }
  statement {
    actions = [
      "s3:*Object",
    ]
    resources = ["${module.s3_performance_reports.arn}/*"]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "additional_task_permissions" {
  name   = "${var.identifier}-task-permissions"
  policy = data.aws_iam_policy_document.additional_task_permissions.json
}

data "aws_iam_policy" "session_manager_access" {
  name = "SessionManagerAccess"
}

################################# IAM Role/Policy Attachments #################################

resource "aws_iam_role_policy_attachment" "base" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "additional" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.additional_task_execution_permissions.arn
}

resource "aws_iam_role_policy_attachment" "task_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.additional_task_permissions.arn
}

resource "aws_iam_role_policy_attachment" "session_manager_access" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = data.aws_iam_policy.session_manager_access.arn
}
