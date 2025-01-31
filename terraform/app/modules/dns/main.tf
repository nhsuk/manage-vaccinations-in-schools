data "aws_route53_zone" "this" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_acm_certificate" "this" {
  domain_name       = "${var.domain_name_prefix}.${data.aws_route53_zone.this.name}"
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = tolist(aws_acm_certificate.this.domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.this.domain_validation_options)[0].resource_record_type
  records = [tolist(aws_acm_certificate.this.domain_validation_options)[0].resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "certificate_validation" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [aws_route53_record.cert_validation.fqdn]
}

resource "aws_route53_record" "app_dns" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "${var.domain_name_prefix}.${data.aws_route53_zone.this.name}"
  type    = "A"

  alias {
    name                   = var.dns_name
    zone_id                = var.zone_id
    evaluate_target_health = true
  }
}
