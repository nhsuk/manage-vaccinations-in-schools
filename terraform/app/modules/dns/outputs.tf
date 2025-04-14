output "certificate_arn" {
  value       = aws_acm_certificate.this.arn
  description = "ARN of the generated ACM certificate"
}
