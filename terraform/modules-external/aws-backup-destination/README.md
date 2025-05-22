# AWS Backup Module

The AWS Backup Module helps automates the setup of AWS Backup resources in a destination account. It streamlines the process of creating, managing, and standardising backup configurations.

## Inputs

| Name                                                                                                                     | Description                                                                                                                                                                                         | Type     | Default        | Required |
| ------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | -------------- | :------: |
| <a name="input_account_id"></a> [account_id](#input_account_id)                                                          | The id of the account that the vault will be in                                                                                                                                                     | `string` | n/a            |   yes    |
| <a name="input_changeable_for_days"></a> [changeable_for_days](#input_changeable_for_days)                               | How long you want the vault lock to be changeable for, only applies to compliance mode. This value is expressed in days no less than 3 and no greater than 36,500; otherwise, an error will return. | `number` | `14`           |    no    |
| <a name="input_enable_vault_protection"></a> [enable_vault_protection](#input_enable_vault_protection)                   | Flag which controls if the vault lock is enabled                                                                                                                                                    | `bool`   | `false`        |    no    |
| <a name="input_kms_key"></a> [kms_key](#input_kms_key)                                                                   | The KMS key used to secure the vault                                                                                                                                                                | `string` | n/a            |   yes    |
| <a name="input_region"></a> [region](#input_region)                                                                      | The region we should be operating in                                                                                                                                                                | `string` | `"eu-west-2"`  |    no    |
| <a name="input_source_account_id"></a> [source_account_id](#input_source_account_id)                                     | The id of the account that backups will come from                                                                                                                                                   | `string` | n/a            |   yes    |
| <a name="input_source_account_name"></a> [source_account_name](#input_source_account_name)                               | The name of the account that backups will come from                                                                                                                                                 | `string` | n/a            |   yes    |
| <a name="input_vault_lock_max_retention_days"></a> [vault_lock_max_retention_days](#input_vault_lock_max_retention_days) | The maximum retention period that the vault retains its recovery points                                                                                                                             | `number` | `365`          |    no    |
| <a name="input_vault_lock_min_retention_days"></a> [vault_lock_min_retention_days](#input_vault_lock_min_retention_days) | The minimum retention period that the vault retains its recovery points                                                                                                                             | `number` | `365`          |    no    |
| <a name="input_vault_lock_type"></a> [vault_lock_type](#input_vault_lock_type)                                           | The type of lock that the vault should be, will default to governance                                                                                                                               | `string` | `"governance"` |    no    |

## Example

```terraform
module "test_backup_vault" {
  source                  = "./modules/aws_backup"
  source_account_name     = "test"
  account_id              = local.aws_accounts_ids["backup"]
  source_account_id       = local.aws_accounts_ids["test"]
  kms_key                 = aws_kms_key.backup_key.arn
  enable_vault_protection = true
}
```
