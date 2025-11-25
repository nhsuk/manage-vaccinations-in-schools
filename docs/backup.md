# Backup documentation

This table documents which data is being backed up to achieve compliance with the Engineering red line CLOUD-6

| Data                           | Storage Type                    | Location                                 | Data Category             | Immutable Backup | Business Use Case                                             | Frequency   | Retention | Notes                                |
| ------------------------------ | ------------------------------- | ---------------------------------------- | ------------------------- | ---------------- | ------------------------------------------------------------- | ----------- | --------- | ------------------------------------ |
| Service Database               | AWS Aurora DB                   | mavis-production                         | Patient Data              | Yes              | All data on vaccinations, schools, teams, consents given etc. | Twice a day | 60 days   |                                      |
| Terraform state                | S3                              | nhse-mavis-terraform-state-production    | System Rebuild Data       | Yes              | Reference of the current infrastructure state                 | Twice a day | 60 days   |                                      |
| Access logs                    | S3                              | nhse-mavis-access-logs-production        | Operational Data          | No               | Access logs for S3 buckets                                    |             |           |                                      |
| Application secrets/parameters | Secretsmanager, Parameter store |                                          | Cloud Infrastructure Data | No               |                                                               |             |           | Can be recreated in case of disaster |
| Container images               | ECR Container Registry          | mavis/webapp, mavis/ops, mavis/reporting | Build artifacts           | No               |                                                               |             |           | Can be rebuilt from GitHub           |
