resource "aws_iam_role" "secret_access" {
  name = "dms_secret_manager_access_role_${var.environment}"
  assume_role_policy = templatefile(
    "./templates/iam_assume_role.json.tpl",
    { service_name = "dms.eu-west-2.amazonaws.com" }
  )
}

data "aws_iam_policy_document" "db_secret_access" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds",
      "secretsmanager:ListSecrets",
      "secretsmanager:*"
    ]
    resources = [
      aws_secretsmanager_secret.source.arn,
      aws_secretsmanager_secret.target.arn
    ]
  }
}

resource "aws_iam_policy" "db_secret_access" {
  name   = "dms_secret_manager_access_policy_${var.environment}"
  policy = data.aws_iam_policy_document.db_secret_access.json
}

resource "aws_iam_role_policy_attachment" "dms_secret_access" {
  role       = aws_iam_role.secret_access.name
  policy_arn = aws_iam_policy.db_secret_access.arn
}

##################

resource "aws_iam_role" "dms_vpc_role" {
  name = "dms-vpc-role"
  assume_role_policy = templatefile(
    "./templates/iam_assume_role.json.tpl",
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
    "./templates/iam_assume_role.json.tpl",
    { service_name = "dms.eu-west-2.amazonaws.com" }
  )
}

resource "aws_iam_role_policy_attachment" "dms_cloudwatch_logs_policy" {
  role       = aws_iam_role.dms_cloudwatch_logs_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole"
}
