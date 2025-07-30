variable "account_id" {
  type        = string
  description = "AWS account ID."
  nullable    = false
}

variable "environment" {
  type        = string
  description = "Environment name (AWS Account level)."
  nullable    = false
  validation {
    condition     = contains(["development", "production"], var.environment)
    error_message = "Valid values for environment: development, production."
  }
}

locals {
  base_policies = {
    read    = "arn:aws:iam::aws:policy/ReadOnlyAccess"
    tagging = "arn:aws:iam::aws:policy/ResourceGroupsTaggingAPITagUntagSupportedResources"
  }

  mavis_deploy_policies = merge(local.base_policies, {
    mavis_deploy = aws_iam_policy.mavis_deploy.arn
  })

  data_replication_policies = merge(local.base_policies, {
    data_replication_deploy = aws_iam_policy.data_replication_deploy.arn
    mavis_deploy            = aws_iam_policy.mavis_deploy.arn
  })

  monitoring_policies = merge(local.base_policies, {
    monitoring_deploy = aws_iam_policy.monitoring_deploy.arn
  })
}
