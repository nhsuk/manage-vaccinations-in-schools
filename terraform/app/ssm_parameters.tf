resource "aws_ssm_parameter" "environment_config" { #TODO: Remove once all variables are sourced from application config
  for_each = local.parameter_store_variables
  name     = "/${var.environment}/env/${each.key}"
  type     = "String"
  value    = each.value

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_ssm_parameter" "cloud_variables" {
  for_each = toset([
    "web", "good-job", "sidekiq"
  ])
  name  = "/${var.environment}/envs/${each.value}"
  type  = "StringList"
  value = "service=${each.value}"

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}
