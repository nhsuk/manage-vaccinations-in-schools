resource "aws_backup_plan" "default" {
  name = "${local.resource_name_prefix}-plan"

  dynamic "rule" {
    for_each = var.backup_plan_config.rules
    content {
      recovery_point_tags = {
        backup_rule_name = rule.value.name
      }
      rule_name         = rule.value.name
      target_vault_name = aws_backup_vault.main.name
      schedule          = rule.value.schedule
      enable_continuous_backup  = rule.value.enable_continuous_backup != null ? rule.value.enable_continuous_backup : null
      lifecycle {
        delete_after       = rule.value.lifecycle.delete_after != null ? rule.value.lifecycle.delete_after : null
        cold_storage_after = rule.value.lifecycle.cold_storage_after != null ? rule.value.lifecycle.cold_storage_after : null
      }
      dynamic "copy_action" {
        for_each = var.backup_copy_vault_arn != "" && var.backup_copy_vault_account_id != "" && rule.value.copy_action != null ? rule.value.copy_action : {}
        content {
          lifecycle {
            delete_after = copy_action.value
          }
          destination_vault_arn = var.backup_copy_vault_arn
        }
      }
    }
  }
}

# this backup plan shouldn't include a continous backup rule as it isn't supported for DynamoDB
resource "aws_backup_plan" "dynamodb" {
  count = var.backup_plan_config_dynamodb.enable ? 1 : 0
  name  = "${local.resource_name_prefix}-dynamodb-plan"

  dynamic "rule" {
    for_each = var.backup_plan_config_dynamodb.rules
    content {
      recovery_point_tags = {
        backup_rule_name = rule.value.name
      }
      rule_name         = rule.value.name
      target_vault_name = aws_backup_vault.main.name
      schedule          = rule.value.schedule
      lifecycle {
        delete_after       = rule.value.lifecycle.delete_after != null ? rule.value.lifecycle.delete_after : null
        cold_storage_after = rule.value.lifecycle.cold_storage_after != null ? rule.value.lifecycle.cold_storage_after : null
      }
      dynamic "copy_action" {
        for_each = var.backup_copy_vault_arn != "" && var.backup_copy_vault_account_id != "" && rule.value.copy_action != null ? rule.value.copy_action : {}
        content {
          lifecycle {
            delete_after = copy_action.value
          }
          destination_vault_arn = var.backup_copy_vault_arn
        }
      }
    }
  }
}

resource "aws_backup_selection" "default" {
  iam_role_arn = aws_iam_role.backup.arn
  name         = "${local.resource_name_prefix}-selection"
  plan_id      = aws_backup_plan.default.id

  selection_tag {
    key   = var.backup_plan_config.selection_tag
    type  = "STRINGEQUALS"
    value = "True"
  }
}

resource "aws_backup_selection" "dynamodb" {
  count        = var.backup_plan_config_dynamodb.enable ? 1 : 0
  iam_role_arn = aws_iam_role.backup.arn
  name         = "${local.resource_name_prefix}-dynamodb-selection"
  plan_id      = aws_backup_plan.dynamodb[0].id

  selection_tag {
    key   = var.backup_plan_config_dynamodb.selection_tag
    type  = "STRINGEQUALS"
    value = "True"
  }
}
