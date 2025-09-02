# Rake Tasks

## `feature_flags:seed`

Set up the feature flags in the database from the configuration.

## `smoke:seed`

Creates a school and a GP practice location suitable for smoke testing in production.

## `vaccines:seed[type]`

- `type` - The type of vaccine, either `flu`, `hpv`, `menacwy` and `td_ipv`. (optional)

This creates the default set of vaccine records, or if they already exist, updates any existing vaccine records to match the default set.

This is useful for setting up a new production environment, but also gets automatically run by `db:seed`.

## `cloudwatch:publish_test_metric`

Publishes a test metric to AWS CloudWatch in the `test/export` namespace. This task sends the following metric data:

- **MetricName**: TestMetric
- **Value**: 1.0
- **Unit**: Count
- **Dimensions**: Environment=Test

**Requirements**: AWS credentials must be configured (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION) with CloudWatch PutMetricData permissions.

**Usage**: This task is useful for testing CloudWatch integration and verifying that metric publishing is working correctly in different environments.
