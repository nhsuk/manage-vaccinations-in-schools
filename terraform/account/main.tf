terraform {
  required_version = "~> 1.11.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.2"
    }
  }

  backend "s3" {
    region       = "eu-west-2"
    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region = "eu-west-2"
}

resource "aws_iam_policy" "data_replication_access" {
  name = "DataReplicationAccess"
  # description = "Allows shell access to Data Replication ECS tasks"
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
