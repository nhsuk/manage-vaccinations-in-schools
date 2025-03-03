locals {
  resource_name_prefix = "${data.aws_region.current.name}-${data.aws_caller_identity.current.account_id}-backup"
}
