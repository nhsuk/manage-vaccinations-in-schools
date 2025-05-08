resource "aws_backup_framework" "main" {
  # must be underscores instead of dashes
  name        = replace("${local.resource_name_prefix}-framework", "-", "_")
  description = "${var.project_name} Backup Framework"

  # Evaluates if recovery points are encrypted.
  control {
    name = "BACKUP_RECOVERY_POINT_ENCRYPTED"

    scope {
      tags = {
        "environment_name" = var.environment_name
      }
    }
  }

  # Evaluates if backup vaults do not allow manual deletion of recovery points with the exception of certain IAM roles.
  control {
    name = "BACKUP_RECOVERY_POINT_MANUAL_DELETION_DISABLED"

    scope {
      tags = {
        "environment_name" = var.environment_name
      }
    }

    input_parameter {
      name  = "principalArnList"
      value = var.terraform_role_arn
    }
  }

  # Evaluates if recovery point retention period is at least 1 month.
  control {
    name = "BACKUP_RECOVERY_POINT_MINIMUM_RETENTION_CHECK"

    scope {
      tags = {
        "environment_name" = var.environment_name
      }
    }

    input_parameter {
      name  = "requiredRetentionDays"
      value = "35"
    }
  }

  # Evaluates if backup plan creates backups at least every 1 day and retains them for at least 1 month before deleting them.
  control {
    name = "BACKUP_PLAN_MIN_FREQUENCY_AND_MIN_RETENTION_CHECK"

    scope {
      tags = {
        "environment_name" = var.environment_name
      }
    }

    input_parameter {
      name  = "requiredFrequencyUnit"
      value = "days"
    }

    input_parameter {
      name  = "requiredRetentionDays"
      value = "35"
    }

    input_parameter {
      name  = "requiredFrequencyValue"
      value = "1"
    }
  }

  # Evaluates if resources are protected by a backup plan.
  control {
    name = "BACKUP_RESOURCES_PROTECTED_BY_BACKUP_PLAN"

    scope {
      compliance_resource_types = var.backup_plan_config.compliance_resource_types
      tags = {
        (var.backup_plan_config.selection_tag) = "True"
      }
    }
  }

  # Evaluates if resources have at least one recovery point created within the past 1 day.
  control {
    name = "BACKUP_LAST_RECOVERY_POINT_CREATED"

    input_parameter {
      name  = "recoveryPointAgeUnit"
      value = "days"
    }

    input_parameter {
      name  = "recoveryPointAgeValue"
      value = "1"
    }

    scope {
      compliance_resource_types = var.backup_plan_config.compliance_resource_types
      tags = {
        (var.backup_plan_config.selection_tag) = "True"
      }
    }
  }
}

resource "aws_backup_framework" "dynamodb" {
  count = var.backup_plan_config_dynamodb.enable ? 1 : 0
  # must be underscores instead of dashes
  name        = replace("${local.resource_name_prefix}-dynamodb-framework", "-", "_")
  description = "${var.project_name} DynamoDB Backup Framework"

  # Evaluates if resources are protected by a backup plan.
  control {
    name = "BACKUP_RESOURCES_PROTECTED_BY_BACKUP_PLAN"

    scope {
      compliance_resource_types = var.backup_plan_config_dynamodb.compliance_resource_types
      tags = {
        (var.backup_plan_config_dynamodb.selection_tag) = "True"
      }
    }
  }

  # Evaluates if resources have at least one recovery point created within the past 1 day.
  control {
    name = "BACKUP_LAST_RECOVERY_POINT_CREATED"

    input_parameter {
      name  = "recoveryPointAgeUnit"
      value = "days"
    }

    input_parameter {
      name  = "recoveryPointAgeValue"
      value = "1"
    }

    scope {
      compliance_resource_types = var.backup_plan_config_dynamodb.compliance_resource_types
      tags = {
        (var.backup_plan_config_dynamodb.selection_tag) = "True"
      }
    }
  }
}
