# Overview of using the DMS module for migrating data from one Aurora postgres RDS cluster to another.

## AWS Resources

### Overview

Overview of resources needed in addition to the DMS module for a successful migration.

- Persisted after migration:
  - Target RDS cluster with custom parameter group to disable foreign key constraints.
  - Two DB instances in the **target** cluster.
  - Secret rotation configuration for the target database.
  - Grant the ECS execution task role access to the target DB secret (in `aws_iam_policy_document.ecs_secrets_access`)
- Removed after migration:
  - Customer parameter group for the **source** RDS cluster to allow logical replication.
  - All resources in [db_migration_config.tf.tpl](resources/db_migration_config.tf.tpl):
    - ECS task based on the dockerized MAVIS image to set up target schema
    - DMS module for migration resources
    - Security group rule connecting ECS task and target DB

### Details on resources

Details of resources needed in addition to the DMS module for a successful migration.

- Create a new Aurora PostgreSQL cluster (target) with the same engine version as the source.
- Create a custom parameter group for the target RDS cluster
  - This ensures the target DB has disabled all triggers (including foreign key constraints) to accommodate the
    initial data dump.
  ```hcl
  resource "aws_rds_cluster_parameter_group" "target" {
    name        = "${var.environment}-disable-constraints"
    family      = "aurora-postgresql16"
    description = "Custom parameter group for Aurora PostgreSQL cluster"
    parameter {
      name         = "session_replication_role"
      value        = "replica" # This needs to be modified to "origin" after the full load is done, as part of configuring ECS tasks to point to the new DB
      apply_method = "immediate"
    }
  }
  ```
- Create a secret rotation configuration for the target DB set to 400 days initially
  ```hcl
  resource "aws_secretsmanager_secret_rotation" "target" {
    secret_id          = aws_rds_cluster.core.master_user_secret[0].secret_arn
    rotate_immediately = false
    rotation_rules {
      schedule_expression = "rate(400 days)" # Change to e.g. "cron(0 8 ? * WED *)" after migration is complete
    }
  }
  ```
- If a source DB secret exists ensure the next rotation is far enough in the future (e.g. 400 days) to allow the
  migration to complete
  - After migration the source DB and secret will be destroyed so it will not need to be rotated again.
- Create 2 DB instances in the target cluster both with promotion-tier set to 1 to allow failover.
  - This will be important to ensure we can change parameters in the cluster without downtime.
- Create a customer parameter group for the source RDS cluster to allow logical replication.
  - This parameter change will require a reboot of the DB instances so having two instances
    in the source cluster will allow us to perform the reboot without downtime using
    failover.
  ```hcl
  resource "aws_rds_cluster_parameter_group" "source" {
    name        = "${var.environment}-custom"
    family      = "aurora-postgresql16"
    description = "Custom parameter group for Aurora PostgreSQL cluster"
    parameter {
      name         = "rds.logical_replication"
      value        = 1
      apply_method = "pending-reboot"
    }
  }
  ```
- We need an ECS service for which we can execute rake commands against the target DB to prepare the schema.
  - As this service will be used to run the `db:drop`, `db:create`, and `db:schema:load` commands against the target
    DB it needs to be based on the same docker image as is deployed to production. Since we do not wish to run the
    application there we can define it as type `none` as
    in [db_migration_config.tf.tpl](resources/db_migration_config.tf.tpl)
  - It also doubles as an access point to the target DB where it will be used to run the `ALTER SEQUENCE` commands
    after the initial data dump is complete.

## Migration steps

### Pre-Migration preparation:

1. Deploy the migration-ready infrastructure configuration. This can be done either:
   1. As part of a normal release
   2. Running the [deploy-infrastructure.yml](../../../../.github/workflows/deploy-infrastructure.yml)
      workflow on a prepared branch/tag, using the already deployed docker image tag to not change the code of the
      running application.
2. Take snapshot of source DB
3. DB failover (this ensures write instance has correct DB parameters)
   1. The read instance will need to be rebooted first if it was not created in step 1.
4. Shell into `mavis-<ENV>-prepare_new_db` service and run
   1. Run `bin/rails db:drop db:create db:schema:load` on `mavis-<ENV>-prepare_new_db` service. This will drop any existing data while still maintaining the database schema.
   2. Run `bin/rails dbconsole` and execute the following commands to prepare the target DB:
   ```postgresql
   TRUNCATE public.schema_migrations;
   TRUNCATE public.ar_internal_metadata;
   ```

### Data Migration & Switchover:

Steps to perform the migration of data and ECS services from source to target.

1. Trigger DB migration task to start
2. Wait until full load is done and migration is in replication mode
3. Update the sequences on target DB
   1. Run [get_alter_sequence_statements.sql](resources/get_alter_sequence_statements.sql) script on source DB
   2. This will generate a set of `ALTER SEQUENCE` SQL commands that need to be executed on the target DB.
      The script will output the commands to the console, which can be copied and executed on the target DB.
   3. The script is configured to add a buffer of 10000 to the current sequence values to handle any potential data
      inserts during switchover. Modify the value of the `sequence_buffer` variable in the script if needed.
4. On target DB execute the ALTER sequence SQL commands
5. Validate new DB content looks good
6. Take snapshot of source DB
7. Deploy infrastructure configuration pointing ECS services to new database.
   1. This is done by running the [deploy-infrastructure.yml](../../../../.github/workflows/deploy-infrastructure.yml)
      workflow on a prepared branch/tag. Use the already deployed docker image tag to not change the code of the
      running application.
   2. Note that this also changes the DB session_replication_role to the default "origin"), which is crucial to ensure
      data consistency on the target DB after the migration.
8. Validate that the target DB has `session_replication_role` set to `origin` in the DB cluster parameter group and is in sync0.
   1. This will requrie a DB instance reboot to apply the parameter change. Reboot the read instance first to avoid
      any downtime, afterward failover and reboot the other DB instance
9. Stop good-job-service (by updating service and setting descried count to 0)
10. Execute CodeDeploy deployment of web-service (after deploy it will point against new service)
11. Stop DMS migration task
12. Execute ECS deployment of good-job-service

### Post-Migration cleanup:

Once the system has been validated to be working properly and any necessary data consistency checks has been performed
the cleanup steps:

1. Disable delete protection on the old source RDS cluster
2. Destroy no-longer needed resources
   1. This is done by running the [deploy-infrastructure.yml](../../../../.github/workflows/deploy-infrastructure.yml)
      workflow on a prepared branch/tag. Use the already deployed docker image tag to not change the code of the
      running application.
   2. This should remove the migration-specific sources and apply post-migration changes like password rotation
      frequency.
   3. The old source DB cluster and all its references should also be destroyed by this deployment.
