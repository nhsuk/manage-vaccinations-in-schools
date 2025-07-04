resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_policy" "secrets_manager_access" {
  name        = "secrets_manager_access"
  description = "Policy to allow Lambda to access Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_rds_cluster.core.master_user_secret[0].secret_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_secrets_manager" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.secrets_manager_access.arn
}

resource "aws_iam_policy" "rds_data_api_access" {
  name        = "rds_data_api_access"
  description = "Policy to allow Lambda to access RDS Data API"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds-data:ExecuteStatement",
          "rds-data:BatchExecuteStatement",
          "rds-data:BeginTransaction",
          "rds-data:CommitTransaction",
          "rds-data:RollbackTransaction"
        ]
        Resource = aws_rds_cluster.core.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_rds_data_api" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.rds_data_api_access.arn
}

resource "aws_security_group" "lambda_sg" {
  name        = "lambda_sg"
  description = "Security group for Lambda function"
  vpc_id      = aws_vpc.application_vpc.id
}

resource "aws_security_group_rule" "lambda_https_egress" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.lambda_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTPS outbound for AWS services (Secrets Manager, RDS Data API)"
}

data "archive_file" "init" {
  type        = "zip"
  source_file = "${path.module}/lambda.py"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "db_scraper" {
  filename                       = data.archive_file.init.output_path
  function_name                  = "db_scraper"
  role                           = aws_iam_role.lambda_exec.arn
  handler                        = "lambda.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 60
  memory_size                    = 128
  reserved_concurrent_executions = 1
  source_code_hash               = data.archive_file.init.output_base64sha256

  vpc_config {
    subnet_ids         = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      SECRET_ARN    = aws_rds_cluster.core.master_user_secret[0].secret_arn
      CLUSTER_ARN   = aws_rds_cluster.core.arn
      DATABASE_NAME = aws_rds_cluster.core.database_name
    }
  }
  lifecycle {
  }
}

resource "aws_cloudwatch_event_rule" "scrape_schedule" {
  name                = "db_scrape_schedule"
  description         = "Trigger Lambda every var.db_scrape_interval minutes"
  schedule_expression = "rate(2 minutes)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.scrape_schedule.name
  target_id = "db_scraper"
  arn       = aws_lambda_function.db_scraper.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.db_scraper.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.scrape_schedule.arn
}
