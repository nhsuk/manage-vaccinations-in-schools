data "aws_s3_bucket" "access_logs" {
  bucket = var.access_logs_bucket
}

module "filetransfer_bucket" {
  source                   = "../modules/s3"
  bucket_name              = "mavis-filetransfer-${var.environment}"
  logging_target_bucket_id = data.aws_s3_bucket.access_logs.id
  logging_target_prefix    = "filetransfer/"
}
