# 15. Move infrastructure-as-code to separate repository

Date: 2026-01-30

## Status

Accept

## Context

Infrastructure code currently describes the infrastructure associated to three repositories: mavis application (this repository), reporting, and testing. However, the infrastructure code is only contained inside the mavis application repository. This creates maintenance challenges and tight coupling between application code and infrastructure releases.

- Reporting repository: https://github.com/NHSDigital/manage-vaccinations-in-schools-reporting
- Testing repository: https://github.com/NHSDigital/manage-vaccinations-in-schools-testing

## Decision

Extract all infrastructure-as-code to a dedicated repository: https://github.com/NHSDigital/manage-vaccinations-in-schools-infrastructure. Already we have done work to reduce dependencies between application and infastructure such that they can be deployed independently.

## Consequences

- Removes infrastructure dependency from application repositories
- Enables independent infrastructure changes
- Requires coordinated release planning when infrastructure changes impact multiple services
- Necessitates a clear versioning strategy for infrastructure components
