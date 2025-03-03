data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_roles" "roles" {
  name_regex  = "AWSReservedSSO_Admin_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}
