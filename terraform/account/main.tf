terraform {
  required_version = "~> 1.11.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.87"
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
