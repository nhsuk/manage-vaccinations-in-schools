resource "aws_iam_role" "ecs_task_role" {
  name               = "EcsTaskRole"
  assume_role_policy = templatefile("../app/templates/iam_assume_role.json.tpl", { service_name = "ecs-tasks.amazonaws.com" })
}

resource "aws_iam_role_policy_attachment" "ecs_task_fargate" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.session_manager_access.arn
}

resource "aws_iam_role_policy_attachment" "ecs_task_cloudwatch_agent" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}


resource "aws_iam_role_policy_attachment" "get_s3_object" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.get_s3_object.arn
}

resource "aws_iam_policy" "session_manager_access" {
  name        = "SessionManagerAccess"
  description = "Allows ECS tasks to be accessed via AWS Systems Manager Session Manager"
  policy      = file("resources/iam_policy_SessionManagerAccess.json")
}

resource "aws_iam_policy" "ecs_shell_access_policy" {
  name        = "EcsShellAccess"
  description = "Allows shell access to ECS tasks"
  policy      = file("resources/iam_policy_EcsShellAccess.json")
}

resource "aws_iam_policy" "deny_pii_access" {
  name        = "DenyPIIAccess"
  description = "Deny access to personal identifiable information"
  policy = templatefile("resources/iam_policy_DenyPIIAccess.json.tftpl", {
    account_id = var.account_id
  })
}

### Service linked role for Database Migration Service (DMS) ###
resource "aws_iam_service_linked_role" "dms_service_linked_role" {
  aws_service_name = "dms.amazonaws.com"
}


### Unique IAM roles
resource "aws_iam_role" "dms_vpc_role" {
  name = "dms-vpc-role"
  assume_role_policy = templatefile(
    "../app/templates/iam_assume_role.json.tpl",
    { service_name = "dms.eu-west-2.amazonaws.com" }
  )
}

resource "aws_iam_role_policy_attachment" "dms_vpc_policy" {
  role       = aws_iam_role.dms_vpc_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
}

# IAM Role for DMS CloudWatch Logs
resource "aws_iam_role" "dms_cloudwatch_logs_role" {
  name = "dms-cloudwatch-logs-role"
  assume_role_policy = templatefile(
    "../app/templates/iam_assume_role.json.tpl",
    { service_name = "dms.eu-west-2.amazonaws.com" }
  )
}

resource "aws_iam_role_policy_attachment" "dms_cloudwatch_logs_policy" {
  role       = aws_iam_role.dms_cloudwatch_logs_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole"
}

resource "aws_iam_policy" "data_replication_access" {
  name        = "DataReplicationAccess"
  description = "Allows shell access to Data Replication ECS tasks"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:ListTasks",
          "ecs:DescribeTasks",
          "ecs:ExecuteCommand"
        ]
        Resource = [
          "arn:aws:ecs:eu-west-2:${var.account_id}:cluster/mavis-*-data-replication*",
          "arn:aws:ecs:eu-west-2:${var.account_id}:task/mavis-*-data-replication*/*",
          "arn:aws:ecs:eu-west-2:${var.account_id}:container-instance/mavis-*-data-replication*/*"
        ]
      }
    ]
  })
  lifecycle {
    ignore_changes = [description]
  }
}

resource "aws_iam_policy" "get_s3_object" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          module.filetransfer_bucket.arn,
          "${module.filetransfer_bucket.arn}/*",
        ]
      }
    ]
  })
  lifecycle {
    ignore_changes = [description]
  }
}
