# Data replication module

## Overview

This module can be used to verify data migration tasks on a copy of actual production data before running them on production.

It creates

- A replication of a given database based on a provided snapshot
- A dedicated ECS service connected to the database

## Masked snapshot requirement

To reduce the access level required for the replication environment, the snapshot used to build the replicated database MUST have the tag `masked=true`. Raw production snapshots containing PII must never be passed directly to this module.

A separate workflow `mask-database-snapshot.yml` takes in the URN of an existing snapshot, anonymizes that and produces a new snapshot tagged `masked=true`. The temporary resources are destroyed afterwards.

Terraform enforces the presence of the `masked=true` tag and will fail if it is missing.

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
