data "aws_route53_zone" "this" {
  name         = var.dns_hosted_zone
  private_zone = false
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "grafana" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "Grafana reverse proxy"
  aliases         = ["grafana.${var.dns_hosted_zone}"]

  tags = {
    Name = "Grafana"
  }

  origin {
    domain_name = var.workspace_url
    origin_id   = "grafana-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "grafana-origin"
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_All"

  viewer_certificate {
    acm_certificate_arn            = module.dns.certificate_arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
    cloudfront_default_certificate = false
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

module "dns" {
  source       = "../../app/modules/dns"
  dns_name     = var.workspace_url
  zone_id      = data.aws_route53_zone.this.id
  zone_name    = var.dns_hosted_zone
  domain_names = ["grafana.${var.dns_hosted_zone}"]
}
