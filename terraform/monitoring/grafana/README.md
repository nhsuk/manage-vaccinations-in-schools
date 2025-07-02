A terraform module to manage Grafana resources.

## Usage

A service account token is required for the Grafana provider. It can be obtained via AWS CLI and needs to be passed as a terraform variable.

```
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
