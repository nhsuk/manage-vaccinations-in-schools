# Create the reports
resource "aws_backup_report_plan" "backup_jobs" {
  name        = "backup_jobs"
  description = "Report for showing whether backups ran successfully in the last 24 hours"

  report_delivery_channel {
    formats = [
      "JSON"
    ]
    s3_bucket_name = var.reports_bucket
    s3_key_prefix  = "backup_jobs"
  }

  report_setting {
    report_template = "BACKUP_JOB_REPORT"
  }
}

# Create the restore testing completion reports
resource "aws_backup_report_plan" "backup_restore_testing_jobs" {
  name        = "backup_restore_testing_jobs"
  description = "Report for showing whether backup restore test ran successfully in the last 24 hours"

  report_delivery_channel {
    formats = [
      "JSON"
    ]
    s3_bucket_name = var.reports_bucket
    s3_key_prefix  = "backup_restore_testing_jobs"
  }

  report_setting {
    report_template = "RESTORE_JOB_REPORT"
  }
}

resource "aws_backup_report_plan" "resource_compliance" {
  name        = "resource_compliance"
  description = "Report for showing whether resources are compliant with the framework"

  report_delivery_channel {
    formats = [
      "JSON"
    ]
    s3_bucket_name = var.reports_bucket
    s3_key_prefix  = "resource_compliance"
  }

  report_setting {
    framework_arns       = var.backup_plan_config_dynamodb.enable ? [aws_backup_framework.main.arn, aws_backup_framework.dynamodb[0].arn] : [aws_backup_framework.main.arn]
    number_of_frameworks = 2
    report_template      = "RESOURCE_COMPLIANCE_REPORT"
  }
}

resource "aws_backup_report_plan" "copy_jobs" {
  count       = var.backup_copy_vault_arn != "" && var.backup_copy_vault_account_id != "" ? 1 : 0
  name        = "copy_jobs"
  description = "Report for showing whether copies ran successfully in the last 24 hours"

  report_delivery_channel {
    formats = [
      "JSON"
    ]
    s3_bucket_name = var.reports_bucket
    s3_key_prefix  = "copy_jobs"
  }

  report_setting {
    report_template = "COPY_JOB_REPORT"
  }
}
