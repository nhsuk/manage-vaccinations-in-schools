# AWS Backup Module

The AWS Backup Module helps automates the setup of AWS Backup resources in a source account. It streamlines the process of creating, managing, and standardising backup configurations.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_backup_copy_vault_account_id"></a> [backup\_copy\_vault\_account\_id](#input\_backup\_copy\_vault\_account\_id) | The account id of the destination backup vault for allowing restores back into the source account. | `string` | `""` | no |
| <a name="input_backup_copy_vault_arn"></a> [backup\_copy\_vault\_arn](#input\_backup\_copy\_vault\_arn) | The ARN of the destination backup vault for cross-account backup copies. | `string` | `""` | no |
| <a name="input_backup_plan_config"></a> [backup\_plan\_config](#input\_backup\_plan\_config) | Configuration for backup plans | <pre>object({<br>    selection_tag             = string<br>    compliance_resource_types = list(string)<br>    rules = list(object({<br>      name                     = string<br>      schedule                 = string<br>      enable_continuous_backup = optional(bool)<br>      lifecycle = object({<br>        delete_after       = optional(number)<br>        cold_storage_after = optional(number)<br>      })<br>      copy_action = optional(object({<br>        delete_after = optional(number)<br>      }))<br>    }))<br>  })</pre> | <pre>{<br>  "compliance_resource_types": [<br>    "S3"<br>  ],<br>  "rules": [<br>    {<br>      "copy_action": {<br>        "delete_after": 365<br>      },<br>      "lifecycle": {<br>        "delete_after": 35<br>      },<br>      "name": "daily_kept_5_weeks",<br>      "schedule": "cron(0 0 * * ? *)"<br>    },<br>    {<br>      "copy_action": {<br>        "delete_after": 365<br>      },<br>      "lifecycle": {<br>        "delete_after": 90<br>      },<br>      "name": "weekly_kept_3_months",<br>      "schedule": "cron(0 1 ? * SUN *)"<br>    },<br>    {<br>      "copy_action": {<br>        "delete_after": 365<br>      },<br>      "lifecycle": {<br>        "cold_storage_after": 30,<br>        "delete_after": 2555<br>      },<br>      "name": "monthly_kept_7_years",<br>      "schedule": "cron(0 2 1  * ? *)"<br>    },<br>    {<br>      "copy_action": {<br>        "delete_after": 365<br>      },<br>      "enable_continuous_backup": true,<br>      "lifecycle": {<br>        "delete_after": 35<br>      },<br>      "name": "point_in_time_recovery",<br>      "schedule": "cron(0 5 * * ? *)"<br>    }<br>  ],<br>  "selection_tag": "BackupLocal"<br>}</pre> | no |
| <a name="input_backup_plan_config_dynamodb"></a> [backup\_plan\_config\_dynamodb](#input\_backup\_plan\_config\_dynamodb) | Configuration for backup plans with dynamodb | <pre>object({<br>    enable                    = bool<br>    selection_tag             = string<br>    compliance_resource_types = list(string)<br>    rules = optional(list(object({<br>      name                     = string<br>      schedule                 = string<br>      enable_continuous_backup = optional(bool)<br>      lifecycle = object({<br>        delete_after       = number<br>        cold_storage_after = optional(number)<br>      })<br>      copy_action = optional(object({<br>        delete_after = optional(number)<br>      }))<br>    })))<br>  })</pre> | <pre>{<br>  "compliance_resource_types": [<br>    "DynamoDB"<br>  ],<br>  "enable": true,<br>  "rules": [<br>    {<br>      "copy_action": {<br>        "delete_after": 365<br>      },<br>      "lifecycle": {<br>        "delete_after": 35<br>      },<br>      "name": "dynamodb_daily_kept_5_weeks",<br>      "schedule": "cron(0 0 * * ? *)"<br>    },<br>    {<br>      "copy_action": {<br>        "delete_after": 365<br>      },<br>      "lifecycle": {<br>        "delete_after": 90<br>      },<br>      "name": "dynamodb_weekly_kept_3_months",<br>      "schedule": "cron(0 1 ? * SUN *)"<br>    },<br>    {<br>      "copy_action": {<br>        "delete_after": 365<br>      },<br>      "lifecycle": {<br>        "cold_storage_after": 30,<br>        "delete_after": 2555<br>      },<br>      "name": "dynamodb_monthly_kept_7_years",<br>      "schedule": "cron(0 2 1  * ? *)"<br>    }<br>  ],<br>  "selection_tag": "BackupDynamoDB"<br>}</pre> | no |
| <a name="input_bootstrap_kms_key_arn"></a> [bootstrap\_kms\_key\_arn](#input\_bootstrap\_kms\_key\_arn) | The ARN of the bootstrap KMS key used for encryption at rest of the SNS topic. | `string` | n/a | yes |
| <a name="input_environment_name"></a> [environment\_name](#input\_environment\_name) | The name of the environment where AWS Backup is configured. | `string` | n/a | yes |
| <a name="input_notifications_target_email_address"></a> [notifications\_target\_email\_address](#input\_notifications\_target\_email\_address) | The email address to which backup notifications will be sent via SNS. | `string` | `""` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | The name of the project this relates to. | `string` | n/a | yes |
| <a name="input_reports_bucket"></a> [reports\_bucket](#input\_reports\_bucket) | Bucket to drop backup reports into | `string` | n/a | yes |
| <a name="input_restore_testing_plan_algorithm"></a> [restore\_testing\_plan\_algorithm](#input\_restore\_testing\_plan\_algorithm) | Algorithm of the Recovery Selection Point | `string` | `"LATEST_WITHIN_WINDOW"` | no |
| <a name="input_restore_testing_plan_recovery_point_types"></a> [restore\_testing\_plan\_recovery\_point\_types](#input\_restore\_testing\_plan\_recovery\_point\_types) | Recovery Point Types | `list(string)` | <pre>[<br>  "SNAPSHOT"<br>]</pre> | no |
| <a name="input_restore_testing_plan_scheduled_expression"></a> [restore\_testing\_plan\_scheduled\_expression](#input\_restore\_testing\_plan\_scheduled\_expression) | Scheduled Expression of Recovery Selection Point | `string` | `"cron(0 1 ? * SUN *)"` | no |
| <a name="input_restore_testing_plan_selection_window_days"></a> [restore\_testing\_plan\_selection\_window\_days](#input\_restore\_testing\_plan\_selection\_window\_days) | Selection window days | `number` | `7` | no |
| <a name="input_restore_testing_plan_start_window"></a> [restore\_testing\_plan\_start\_window](#input\_restore\_testing\_plan\_start\_window) | Start window from the scheduled time during which the test should start | `number` | `1` | no |
| <a name="input_terraform_role_arn"></a> [terraform\_role\_arn](#input\_terraform\_role\_arn) | ARN of Terraform role used to deploy to account | `string` | n/a | yes |

## Example

```terraform
module "test_aws_backup" {
  source = "./modules/aws-backup"

  environment_name                   = "environment_name"
  bootstrap_kms_key_arn              = kms_key[0].arn
  project_name                       = "testproject"
  reports_bucket                     = "compliance-reports"
  terraform_role_arn                 = data.aws_iam_role.terraform_role.arn
}
```
