output "dms_service_role_arn" {
  value       = aws_iam_service_linked_role.dms_service_linked_role.arn
  description = "ARN of the DMS service-linked role"
}
