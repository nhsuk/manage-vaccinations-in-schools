################################# IAM Roles #################################
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole-${var.identifier}"

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
    actions = [
      "s3:ListBucket",
    ]
    resources = [aws_s3_bucket.this.arn]
    effect    = "Allow"
  }
  statement {
    actions = [
      "s3:*Object",
    ]
    resources = ["${aws_s3_bucket.this.arn}/*"]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "additional_task_execution_permissions" {
  name   = "${var.identifier}-task-execution-permissions"
  policy = data.aws_iam_policy_document.additional_task_execution_permissions.json
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
