output "security_group_id" {
  value = "aws_security_group.ecs_background_service_sg.id"
  description = "The ID of the security group for the background service"
}
