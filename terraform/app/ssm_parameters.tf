resource "aws_ssm_parameter" "core_environment_overwrites" {
  for_each = local.parameter_store_variables["CORE"]
  name     = "/${var.environment}/env/core/${each.key}"
  type     = "String"
  value    = each.value

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_ssm_parameter" "reporting_environment_overwrites" {
  for_each = local.parameter_store_variables["REPORTING"]
  name     = "/${var.environment}/env/reporting/${each.key}"
  type     = "String"
  value    = each.value

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_secretsmanager_secret" "jwt_sign" {
  name                    = "rep-jwt-signing-secret-${var.environment}"
  description             = "Secret for jwt signing"
  recovery_window_in_days = 7
  tags = {
    Name = "jwt-signing-${var.environment}"
  }
}

resource "aws_secretsmanager_secret" "reporting_flask" {
  name                    = "reporting-cookie-secret-${var.environment}"
  description             = "Secret for signing cookies in the reporting service"
  recovery_window_in_days = 7
  tags = {
    Name = "reporting-cookie-secret-${var.environment}"
  }
}

ephemeral "aws_secretsmanager_random_password" "reporting_flask" {
  password_length = 42
}

resource "aws_secretsmanager_secret_version" "source" {
  secret_id                = aws_secretsmanager_secret.reporting_flask.id
  secret_string_wo         = ephemeral.aws_secretsmanager_random_password.reporting_flask.random_password
  secret_string_wo_version = var.reporting_flask_secret_version
}

resource "aws_secretsmanager_secret_rotation" "jwt_sign" {
  secret_id           = aws_secretsmanager_secret.jwt_sign.arn
  rotate_immediately  = true
  rotation_lambda_arn = aws_lambda_function.rotate_jwt_sign.arn
  rotation_rules {
    schedule_expression = "cron(0 1 ? * MON *)" # Rotate every Monday at 01:00 UTC
    duration            = "1h"
  }
}

data "archive_file" "jwt_sign_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/resources/rotate_secret.py" # Directory containing the Lambda function code
  output_path = "${path.module}/resources/rotate_secret.zip"
}

resource "aws_lambda_function" "rotate_jwt_sign" {
  function_name    = "rep-jwt-secret-rotation-${var.environment}"
  handler          = "rotate_secret.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.jwt_rotate_lambda.arn
  filename         = data.archive_file.jwt_sign_lambda_zip.output_path
  source_code_hash = data.archive_file.jwt_sign_lambda_zip.output_base64sha256
}

resource "aws_iam_role" "jwt_rotate_lambda" {
  name = "secret-rotation-lambda-role"

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

resource "aws_iam_role_policy" "jwt_rotate_lambda" {
  name = "secret-rotation-lambda-policy"
  role = aws_iam_role.jwt_rotate_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:RotateSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:UpdateSecretVersionStage",
        ]
        Resource = aws_secretsmanager_secret.jwt_sign.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "secretsmanager:GetRandomPassword",
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_permission" "jwt_sign" {
  statement_id  = "AllowExecutionFromSecretsManager"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rotate_jwt_sign.function_name
  principal     = "secretsmanager.amazonaws.com"
  source_arn    = aws_secretsmanager_secret.jwt_sign.arn
}