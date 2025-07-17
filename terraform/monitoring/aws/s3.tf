module "redirect_bucket" {
  source      = "../../modules/s3"
  bucket_name = local.bucket_name
}

resource "aws_s3_bucket_website_configuration" "redirect" {
  bucket = module.redirect_bucket.bucket_id

  redirect_all_requests_to {
    host_name = aws_grafana_workspace.this.endpoint
    protocol  = "https"
  }
}

# S3 public access (required for website)
resource "aws_s3_bucket_public_access_block" "redirect" {
  bucket = module.redirect_bucket.bucket_id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
