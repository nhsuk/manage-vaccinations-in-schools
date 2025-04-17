resource "aws_appautoscaling_target" "ecs_target" {
  count              = length(var.autoscaling_policies) == 0 ? 0 : 1
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.this.name}"
  max_capacity       = var.maximum_replica_count
  min_capacity       = var.minimum_replica_count
  service_namespace  = "ecs"
  scalable_dimension = "ecs:service:DesiredCount"
}


resource "aws_appautoscaling_policy" "ecs_cpu" {
  for_each           = var.autoscaling_policies
  name               = "${var.server_type}-${each.key}-scaling-${var.environment}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = each.value.predefined_metric_type
    }
    target_value       = each.value.target_value
    scale_in_cooldown  = each.value.scale_in_cooldown
    scale_out_cooldown = each.value.scale_out_cooldown
  }
}
