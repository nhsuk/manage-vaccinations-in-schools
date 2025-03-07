variable "bucket_name" {
  description = "The name of the S3 bucket to create"
  type        = string
  nullable    = false
}

variable "logging_target_bucket_id" {
  description = "The id of the S3 bucket to store access logs of this bucket"
  type        = string
  default     = ""
}

variable "logging_target_prefix" {
  description = "The prefix under which the access logs will be stored in the logging bucket"
  type        = string
  default     = ""
}

