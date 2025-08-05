# Data replication module

## Overview

This module can be used to verify data migration tasks on a copy of actual production data before running them on production.

It creates

- A replication of a given database based on a provided snapshot
- A dedicated ECS service connected to the database

## Setup

This module is managed via a GitHub Actions workflow. To separate it from the rest of the infrastructure, the workflow uses a dedicated IAM role called `GithubDeployDataReplicationInfrastructure`.
It is managed in the `terraform/account` module.

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

### Enable egress

To enable egress from the ECS task, e.g. for debugging purposes, simply do a `nslookup` for the required domains add the allowed CIDR ranges as input to the `data-replication-pipeline.yml`.
Domains that have been used in the past are `api.service.nhs.uk` and `get-information-schools.service.gov.uk`.
