# Data masking module

# Overview

A separate workflow `mask-database-snapshot.yml` restores a raw snapshot into a temporary cluster, runs sanitization scripts to remove or 
anonymize PII, validates the removal, and then produces a new snapshot tagged `masked=true`. The temporary resources get destroyed 
afterwards.

It produces a masked version of the snapshot, which then gets stored as a snapshot with the tag `masked=true`.

## Anonymization
In order to anonymize, a salt is generated in the temporary cluster. That salt is used to hash all string values so that equality remains
preserved but PII is removed from the database. 

Dates are randomized but remain within the same academic year.

## Usage

### Steps to produce a masked snapshot

1. Trigger the `Mask DB Snapshot` workflow (`mask-database-snapshot.yml`) providing the raw production snapshot identifier or ARN.
2. Wait for the workflow to finish and note the `Masked snapshot ARN` from the run output.
3. Use that ARN for other uses, such as using it as the `imported_snapshot` input for the deploy replication workflows.

