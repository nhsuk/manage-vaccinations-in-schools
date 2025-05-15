# Data replication module

## Overview

This module can be used to verify data migration tasks on a copy of actual production data before running them on production.

It creates

- A replication of a given database based on a provided snapshot
- A dedicated ECS service connected to the database

## Setup

This module is managed via a GitHub Actions workflow. To separate it from the rest of the infrastructure, the workflow uses a dedicated IAM role. To set up everything from scratch, manually create the role
`GithubDeployDataReplicationInfrastructure` based on the policy template `github_data_replication_actions_policy.json` and the trust policy `github_role_<ENVIRONMENT>_trust_policy.json`.

## Usage

### Manage the database replication infrastructure

To create the infrastructure, run the `data-replication-pipeline.yml` workflow and select the 'Recreate' option.
This will destroy any existing replication infrastructure and create a new replicated database from the latest snapshot.

To destroy the resources, run the `data-replication-pipeline.yml` with the 'Destroy' option.

### Connect to the dedicated ECS task

To connect to the dedicated ECS task, run

```
./script/shell.sh <ENV>-data-replication
```
