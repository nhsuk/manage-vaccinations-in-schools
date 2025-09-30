A terraform module to manage Grafana resources.

## Resources

This module creates Grafana dashboards from the dashboard configuration that is stored in the [resources](resources) folder.

## Usage

A service account token is required for the Grafana provider. The [tf_grafana.sh](../tf_grafana.sh) script shall be used
for any terraform commands. It takes care of obtaining a valid service account token as well as deleting expired tokens.

## Variables

- `service_account_token`: Grafana service account token (required)
- `workspace_url`: URL of the Grafana workspace
- `region`: AWS region (defaults to eu-west-2)

Note: Database cluster selection is now handled through the Grafana dashboard dropdown interface, not through Terraform variables.

## Alert exports

Alerts can be exported from Grafana and managed in this repository. To export alerts, use the Grafana UI to export the alert configuration as Terraform code.
Save the exported code in modules/$environment_alerts/alerts.tf.tpl.
