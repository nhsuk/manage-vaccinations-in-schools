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
