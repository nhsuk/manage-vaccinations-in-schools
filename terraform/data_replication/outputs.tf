output "task_definition_arn" {
  description = "The task definition arn of the db access service"
  value       = module.db_access_service.task_definition.arn
}
