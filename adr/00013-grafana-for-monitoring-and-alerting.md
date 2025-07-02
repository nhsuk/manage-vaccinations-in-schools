# 13. Amazon Managed Grafana for Monitoring and Alerting

Date: 2025-07-01

## Status

Accepted

## Context

Currently, monitoring is done via CloudWatch and alerts are based on Sentry. We want to improve the monitoring and
alerting capabilities of the Mavis application by integrating a more robust and unified solution.

### Acceptance Criteria

1. Fully cloud native solution that integrates with AWS services.
2. Monitoring does not require access to the AWS console.
3. Can be fully managed and automated using terraform.
4. Aligns with TechRadar's accepted technologies.
5. Authentication aligns with existing Identity and Access Management (IAM) setup.
6. Allows Alerts to be configured and managed within the same platform.

## Considered Options

### Option 1 : AWS CloudWatch Dashboards and Alarms

This option involves expanding our use of the native AWS CloudWatch service for all monitoring and alerting, creating
more sophisticated dashboards and migrating all alerts to CloudWatch Alarms.

- **Pros**:
  - Deeply integrated with all AWS services.
  - Fully manageable via Terraform.
  - Provides both dashboarding and alerting in a single service.
- **Cons**:
  - Less flexible and powerful dashboarding capabilities.
  - User experience requires returning to the AWS console.

### Option 2 : Splunk

This option would involve leveraging our existing Splunk integration to handle not just log aggregation but also
metric-based monitoring and alerting.

- **Pros**:
  - Powerful alerting features based on complex log queries.
  - Can view dashboards without accessing the AWS console.
- **Cons**:
  - Primarily a log analysis tool, not ideal for metric-based monitoring.
  - Integrating it AWS is more difficult as it is an external service.
  - Restricting NHS-wide access to dashboards and alerts would require additional configuration.

### Option 3 : Amazon OpenSearch Service

This involves using the managed OpenSearch service, which includes OpenSearch Dashboards and an integrated alerting
plugin.

- **Pros**:
  - Fully managed AWS service.
  - Provides powerful log analytics, visualization, and alerting.
  - Can view dashboards without accessing the AWS console.
- **Cons**:
  - Core strength is in log data, not metrics.
  - Metric-based alerting setup is more complex than specialized tools.
  - Potentially overkill for our primary requirements.

### Option 4 : Amazon Managed Grafana

A fully managed service for the open-source Grafana platform, which is a popular tool for analytics, interactive
visualization, and alerting.

- **Pros**:
  - Purpose-built for unified dashboards and alerting.
  - Best-in-class visualization capabilities.
  - Integrates seamlessly with CloudWatch and AWS IAM Identity Center.
  - Fully manageable via Terraform.
  - Can view dashboards without accessing the AWS console.
- **Cons**:
  - Introduces a new service to the architecture.

## Decision

We will adopt **Amazon Managed Grafana** as our primary monitoring and alerting solution.

It is the only option that excels at meeting all our acceptance criteria, especially the need for a unified platform for
both visualization and alerting. It provides best-in-class dashboard features while also integrating an alerting system.
The service also integrates well with multiple types of data (logs, streams, metrics, etc.)
This allows us to consolidate our tooling and deprecate the use of Sentry for alerts, creating a more streamlined
operational workflow. Its native integration with AWS for data sources (CloudWatch) and authentication (IAM Identity
Center) makes it a natural fit, and as an AWS Service it is tech radar accepted.

## Consequences

- We will provision a new Amazon Managed Grafana workspace using Terraform.
- User access will be managed via AWS IAM Identity Center, granting authorized personnel access to dashboards and alert
  configurations without needing to log into the AWS console.
- CloudWatch will be configured as the primary data source within Grafana.
- An initial set of dashboards for key application and infrastructure metrics (e.g., CPU/Memory utilization, database
  connections, latency) will be created.
- All future alerting will be configured and managed within Grafana, deprecating our reliance on Sentry for this
  purpose.
