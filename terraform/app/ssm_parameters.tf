resource "aws_ssm_parameter" "pds_wait_between_jobs" {
  name = "/${var.environment}/pds_wait_between_jobs"
  type = "String"

  # This value is the default, but can be customised in the AWS console
  # directly and isn't managed by Terraform.
  value = "2"

  lifecycle {
    ignore_changes = [value]
  }
}
