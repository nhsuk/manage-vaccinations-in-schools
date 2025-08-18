resource "aws_security_group" "valkey" {
  name        = "mavis-cache-${var.environment}"
  description = "Security group for Valkey ElastiCache (self-designed cluster)"
  vpc_id      = aws_vpc.application_vpc.id

  tags = {
    Name = "mavis-cache-${var.environment}"
  }

  lifecycle {
    ignore_changes = [description]
  }
}

resource "aws_security_group_rule" "valkey_ecs_services_ingress" {
  count                    = length(local.ecs_sg_ids)
  type                     = "ingress"
  from_port                = var.valkey_port
  to_port                  = var.valkey_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.valkey.id
  source_security_group_id = local.ecs_sg_ids[count.index]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elasticache_subnet_group" "valkey" {
  name       = "mavis-cache-subnet-group-${var.environment}"
  subnet_ids = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]

  tags = {
    Name = "mavis-cache-subnet-group-${var.environment}"
  }
}

resource "aws_elasticache_replication_group" "valkey" {
  replication_group_id = "mavis-cache-${var.environment}"
  description          = "Valkey cluster for Sidekiq"

  engine               = "valkey"
  engine_version       = var.valkey_engine_version
  node_type            = var.valkey_node_type
  port                 = var.valkey_port
  parameter_group_name = aws_elasticache_parameter_group.valkey.name

  automatic_failover_enabled  = var.valkey_failover_enabled
  num_cache_clusters          = length(local.valkey_cache_availability_zones)
  subnet_group_name           = aws_elasticache_subnet_group.valkey.name
  security_group_ids          = [aws_security_group.valkey.id]
  preferred_cache_cluster_azs = local.valkey_cache_availability_zones
  snapshot_retention_limit    = var.valkey_snapshot_retention_limit
  snapshot_window             = var.valkey_snapshot_window
  maintenance_window          = var.valkey_maintenance_window

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.valkey_slow_log.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "slow-log"
  }

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.valkey_engine_log.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "engine-log"
  }

  tags = {
    Name    = "mavis-cache-${var.environment}"
    Purpose = "sidekiq-job-processing"
  }
  apply_immediately = true
}

resource "aws_elasticache_parameter_group" "valkey" {
  family = "valkey8"
  name   = "mavis-cache-params-${var.environment}"

  # Optimize for Sidekiq workload
  parameter {
    name  = "maxmemory-policy"
    value = "noeviction"
  }

  tags = {
    Name = "mavis-cache-params-${var.environment}"
  }
}

resource "aws_cloudwatch_log_group" "valkey_slow_log" {
  name              = "/aws/elasticache/valkey/${var.environment}/slow-log"
  retention_in_days = var.valkey_log_retention_days

  tags = {
    Name = "mavis-cache-slow-log-${var.environment}"
  }
}

resource "aws_cloudwatch_log_group" "valkey_engine_log" {
  name              = "/aws/elasticache/valkey/${var.environment}/engine-log"
  retention_in_days = var.valkey_log_retention_days

  tags = {
    Name = "mavis-cache-engine-log-${var.environment}"
  }
}