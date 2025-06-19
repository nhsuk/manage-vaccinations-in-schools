output "endpoint_id" {
  description = "ID of the VPC endpoint"
  value       = aws_vpc_endpoint.this.id
}

output "endpoint_arn" {
  description = "ARN of the VPC endpoint"
  value       = aws_vpc_endpoint.this.arn
}

output "sg_id" {
  description = "ID of the VPC endpoint's security group"
  value       = aws_security_group.this.id
}

output "sg_arn" {
  description = "ARN of the VPC endpoint's security group"
  value       = aws_security_group.this.arn
}

output "dns_name" {
  value       = aws_vpc_endpoint.this.dns_entry[0].dns_name
  description = "DNS name of the VPC endpoint"
}
