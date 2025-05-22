variable "bucket_name" {
  description = "The name of the S3 bucket to create"
  type        = string
  nullable    = false
}

variable "logging_target_bucket_id" {
  description = "The id of the S3 bucket to store access logs of this bucket"
  type        = string
  default     = ""
  nullable    = false
}

variable "logging_target_prefix" {
  description = "The prefix under which the access logs will be stored in the logging bucket"
  type        = string
  default     = ""
  nullable    = false
}

variable "additional_policy_statements" {
  description = "The JSON policy to apply to the bucket"
  type        = list(any)
  default     = []
}

