# 8. Infrastructure management tooling

Date: 2025-02-26

## Status

Accepted

## Context

So far, the infrastructure for Mavis has been managed with AWS Copilot. While it worked well for the initial phase
of the project, AWS Copilot also has some drawbacks:

#### Opinionated Defaults

AWS Copilot imposes a certain service architecture and default values.
While it's possible to customize the generated configuration to some extent by overwriting the Cloudformation resources,
this is cumbersome and AWS Copilot doesn't provide any benefits here.

#### Integration of NHS Terraform modules

NHSDigital provides Terraform modules for common infrastructure components. In particular, there exists a cloud backup
module (https://github.com/NHSDigital/terraform-aws-backup/) which according to the Red Lines document must be used for backups.
It's not possible to integrate a Terraform module with AWS Copilot.

#### Uncertain future of AWS Copilot

Despite no official announcement, AWS Copilot seems not to be maintained anymore.
The last release happened 8 months ago in June 2024. Before that, releases occurred roughly monthly. According to
https://github.com/aws/copilot-cli/issues/5987, there was already an official announcement for end of support which got removed again.

For this reason we would in any case want to replace AWS Copilot as the infrastructure management tool.

## Decision

We will use Terraform to manage our infrastructure. This is based on

- Terraform is a logical choice as it allows to use the NHS Terraform modules easily.
- Terraform widely used and has a large community.
- AWS Copilot future is uncertain

## Consequences

A proof of concept with Terraform has already been created and has been accepted. Each environment must be now migrated to Terraform.
