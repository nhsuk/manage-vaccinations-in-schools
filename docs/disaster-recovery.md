# Disaster recovery ops manual

## Restoring a production database using a snapshot

Spin up a new environment with an empty database. Follow the instructions in
[Terraform: Creating a new
environment](terraform.md#creating-a-new-environment).

Go to the RDS > Snapshots page in the AWS console. From the System tab, find a
snapshot you want to restore and copy it to a Manual snapshot.

Or, via the CLI:

```sh
# Get the snapshot ARN
aws rds describe-db-cluster-snapshots \
  --query 'reverse(sort_by(DBClusterSnapshots,&SnapshotCreateTime))[*].[DBClusterSnapshotArn]' \
  --output table

# Copy the snapshot to a manual snapshot
aws rds copy-db-cluster-snapshot \
  --source-db-cluster-snapshot-identifier NAME_OF_SNAPSHOT \
  --target-db-cluster-snapshot-identifier NAME_OF_MANUAL_SNAPSHOT
```

In `terraform/app/rds.tf`, add the snapshot ARN as `snapshot_identifier` to the `aws_rds_cluster` resource block.

Disable deletion protection for the old cluster:

```sh
# Get the cluster name
aws rds describe-db-clusters \
  --query 'DBClusters[*].[DBClusterIdentifier]' \
  --output table

# Disable deletion protection
aws rds modify-db-cluster \
  --db-cluster-identifier NAME_OF_OLD_CLUSTER \
  --no-deletion-protection
```

Deploy to your restored environment as described in [Terraform: Local deployment](terraform.md#local-deployment).

## Getting a local dump of an Aurora DB

You need Postgres 16+ to connect to the Aurora DB.

First provision a new DB cluster and instance from an existing snapshot:

```sh
# Get the 5 most recent database snapshots
aws rds describe-db-cluster-snapshots \
  --query 'reverse(sort_by(DBClusterSnapshots,&SnapshotCreateTime))[0:5].[DBClusterSnapshotIdentifier]' \
  --output table

# Get a subnet group name
aws rds describe-db-subnet-groups \
  --query 'DBSubnetGroups[*].[DBSubnetGroupName]' \
  --output table

# Create the cluster
aws rds restore-db-cluster-from-snapshot \
  --db-cluster-identifier mavis-dr-cluster \
  --snapshot-identifier NAME_OF_SNAPSHOT \
  --db-subnet-group-name NAME_OF_SUBNET_GROUP \
  --engine aurora-postgresql

# Wait for the cluster to be ready
aws rds wait db-cluster-available \
  --db-cluster-identifier mavis-dr-cluster && say "Cluster is ready"

# Create the instance; --publicly-accessible is required to connect
aws rds create-db-instance \
  --db-instance-identifier mavis-dr-instance \
  --db-cluster-identifier mavis-dr-cluster \
  --db-instance-class db.t3.medium \
  --engine aurora-postgresql \
  --publicly-accessible

# Wait for the instance to be ready
aws rds wait db-instance-available \
  --db-instance-identifier mavis-dr-instance && say "Instance is ready"
```

Then add a firewall exception for your IP address and check if you can connect:

```sh
# Get the security group ID
aws rds describe-db-clusters \
  --db-cluster-identifier mavis-dr-cluster \
  --query 'DBClusters[*].VpcSecurityGroups[*].[VpcSecurityGroupId]' \
  --output text

# Add your IP address to the security group inbound rules
aws ec2 authorize-security-group-ingress \
  --group-id NAME_OF_SECURITY_GROUP \
  --protocol tcp \
  --port 5432 \
  --cidr $(curl -s checkip.amazonaws.com)/32

# Get the endpoint
aws rds describe-db-instances \
  --db-instance-identifier mavis-dr-instance \
  --query "DBInstances[*].Endpoint.Address" \
  --output text

# Test the connection
nc -zv mavis-dr-instance.xxx.eu-west-2.rds.amazonaws.com 5432
# Should say "Connection to ... succeeded!"

# Make sure it's 16+
psql --version
```

Finally, get the database password and make a local dump:

```sh
# Get the secret name
aws secretsmanager list-secrets \
  --query 'SecretList[*].[Name,Description]' \
  --output table

# Get the database password
aws secretsmanager get-secret-value \
  --secret-id NAME_OF_SECRET \
  --query 'SecretString' \
  --output text | jq -r '.password'

# Make a local dump
pg_dump \
  --host=mavis-dr-instance.xxx.eu-west-2.rds.amazonaws.com \
  --port=5432 \
  --username=postgres \
  --dbname=manage_vaccinations \
  --file=scratchpad/backup.sql \
  --verbose
```

### Cleaning up

Remove the firewall rules and delete the instance and cluster:

```sh
# Remove the inbound rules we added
aws ec2 revoke-security-group-ingress \
  --group-id NAME_OF_SECURITY_GROUP \
  --protocol tcp \
  --port 5432 \
  --cidr $(curl -s checkip.amazonaws.com)/32

# Delete the instance
aws rds delete-db-instance \
  --db-instance-identifier mavis-dr-instance

# Delete the cluster
aws rds delete-db-cluster \
  --db-cluster-identifier mavis-dr-cluster \
  --skip-final-snapshot
```

## Running a local web server from a dump

Load the dump into a local DB:

```sh
createdb manage_vaccinations_staging
psql --dbname=manage_vaccinations_staging < scratchpad/backup.sql
```

Disable SSL in `config/environments/production.rb`:

```rb
config.force_ssl = false
```

Precompile assets:

```sh
RAILS_ENV=staging rails assets:precompile
```

Start the web server:

```sh
RAILS_ENV=staging rails s
```

## Exporting an organisation

Generate an export and encrypt it:

```sh
RAILS_ENV=staging bin/bundle exec \
  ruby script/organisation_export.rb <organisation_id>
EXPORT_PASSWORD=secure \
  node ./script/encrypt_xlsx.mjs <filename>
```

## Set up a new AWS account from scratch

### Create a new IAM role for GitHub workflows

In the AWS IAM console, create a new role for the GitHub workflows. Create a custom policy from `terraform/resources/github_actions_policy.json`. Also, attach the managed policies

- `ReadOnlyAccess`
- `ResourceGroupsTaggingAPITagUntagSupportedResources`

to the role.
