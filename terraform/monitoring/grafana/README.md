A terraform module to manage Grafana resources.

## Resources

This module creates:

- CloudWatch data source for AWS metrics
- Database Dashboard for Aurora PostgreSQL monitoring

## Database Dashboard

The database dashboard monitors key metrics for Aurora PostgreSQL Serverless v2 clusters with support for multiple development environment clusters.

### Cluster Selection

The dashboard includes a dropdown selector at the top that allows you to choose between different database clusters:

- **mavis-qa**: QA environment cluster
- **mavis-preview**: Preview environment cluster
- **mavis-test**: Test environment cluster
- **mavis-training**: Training environment cluster

All clusters are part of the development environment and can be monitored using the same dashboard by selecting the desired cluster from the dropdown.

### Monitored Metrics

- **CPU Utilization**: Shows current CPU usage with thresholds (70% yellow, 90% red)
- **Database Connections**: Monitors active database connections
- **Aurora Serverless Capacity Units**: Tracks scaling of serverless capacity
- **Read/Write IOPS**: Input/output operations per second
- **Read/Write Latency**: Database response times
- **Free Storage Space**: Available storage with thresholds
- **Deadlocks**: Database deadlock occurrences

## Usage

A service account token is required for the Grafana provider. It can be obtained via AWS CLI and needs to be passed as a terraform variable.

### Development Environment

```bash
terraform apply \
    -var="service_account_token=$(
        aws grafana create-workspace-service-account-token \
            --name grafana-token-$(uuidgen) \
            --seconds-to-live 600 \
            --service-account-id 4 \
            --workspace-id g-8c11674eda \
            --query 'serviceAccountToken.key' \
            --output text
    )" \
    -var-file=env/development.tfvars
```

### Production Environment

```bash
terraform apply \
    -var="service_account_token=$(
        aws grafana create-workspace-service-account-token \
            --name grafana-token-$(uuidgen) \
            --seconds-to-live 600 \
            --service-account-id 4 \
            --workspace-id g-8c11674eda \
            --query 'serviceAccountToken.key' \
            --output text
    )" \
    -var-file=env/production.tfvars
```

## Variables

- `service_account_token`: Grafana service account token (required)
- `workspace_url`: URL of the Grafana workspace
- `region`: AWS region (defaults to eu-west-2)

Note: Database cluster selection is now handled through the Grafana dashboard dropdown interface, not through Terraform variables.
