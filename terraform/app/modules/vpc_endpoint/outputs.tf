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
