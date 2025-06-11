
resource "aws_iam_role" "secret_access" {
  name = "dms-secret-manager-access-role-${var.environment}"
  assume_role_policy = templatefile(
    local.assume_role_policy_template,
    { service_name = "dms.eu-west-2.amazonaws.com" }
  )
}

data "aws_iam_policy_document" "db_secret_access" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [
      aws_secretsmanager_secret.source.arn,
      aws_secretsmanager_secret.target.arn
    ]
  }
}

resource "aws_iam_policy" "db_secret_access" {
  name   = "dms-secret-manager-access-policy-${var.environment}"
  policy = data.aws_iam_policy_document.db_secret_access.json
}

resource "aws_iam_role_policy_attachment" "dms_secret_access" {
  role       = aws_iam_role.secret_access.name
  policy_arn = aws_iam_policy.db_secret_access.arn
}
