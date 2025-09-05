# Reporting

The reporting service is a separate Python microservice as per
[ADR 11](../adr/00011-develop-reporting-component-in-python.md).

The codebase is:

https://github.com/NHSDigital/manage-vaccinations-in-schools-reporting

For the reporting functionality, you need to run it in parallel to Mavis.

## Configuration

When developing locally, you can override the default settings in
`config/settings/development.local.yml`:

```yml
reporting_api:
  client_app:
    token_ttl_seconds: 600
    root_url: http://localhost:5001 # Or the URL for the reporting app
    client_id: match_to_.env_in_reporting
    secret: match_to_.env_in_reporting
```
