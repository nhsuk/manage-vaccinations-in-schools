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

## Alerts

### Configuring Alerts

Alerts should be configured in Grafana. The configuration should then be exported and stored in the code.

1. Configure alerts in the Grafana UI.
2. Export the alert rules as Terraform (HCL).
3. Save the exported code in modules/$environment_alerts/alerts.tf.tpl.

### Importing Alerts

There is no need to import alerts into the state. However, it is possible to do so. The script [generate_alert_config.sh](../generate_alert_config.sh) can be used to generate valid terraform syntax.
Before it can be applied, the existing resources must still be imported into the state.
