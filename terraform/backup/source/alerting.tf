data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/backup_alert.py"
  output_path = "${path.module}/lambda/backup_alert_function.zip"
}

resource "aws_iam_role" "lambda_execution" {
  name = "LambdaExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_execution" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_lambda_function" "slack_alert" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "backup_alert"
  description      = "An SNS trigger that sends alert notifications from the backup job to Slack"
  role             = aws_iam_role.lambda_execution.arn
  handler          = "backup_alert.lambda_handler"
  runtime          = "python3.13"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.slack_webhook_url
      ENVIRONMENT       = var.environment
    }
  }
}

data "aws_sns_topic" "backup" {
  name       = "eu-west-2-${var.source_account_id}-backup-notifications"
  depends_on = [module.source]
}

resource "aws_lambda_permission" "with_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_alert.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = data.aws_sns_topic.backup.arn
}

resource "aws_sns_topic_subscription" "lambda_trigger" {
  topic_arn     = data.aws_sns_topic.backup.arn
  protocol      = "lambda"
  endpoint      = aws_lambda_function.slack_alert.arn
  filter_policy = jsonencode({ "State" : [{ "anything-but" : "COMPLETED" }] })
}
