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

# ElastiCache Replication Group (cluster mode disabled for Sidekiq compatibility)
resource "aws_elasticache_replication_group" "valkey" {
  replication_group_id = "mavis-cache-${var.environment}"
  description          = "Valkey cluster for Sidekiq (cluster mode disabled)"

  engine               = "valkey"
  engine_version       = var.valkey_engine_version
  node_type            = var.valkey_node_type
  port                 = var.valkey_port
  parameter_group_name = aws_elasticache_parameter_group.valkey.name

  # Cluster configuration (disabled for Sidekiq compatibility)
  automatic_failover_enabled  = true
  num_cache_clusters          = 2
  subnet_group_name           = aws_elasticache_subnet_group.valkey.name
  security_group_ids          = [aws_security_group.valkey.id]
  preferred_cache_cluster_azs = [aws_subnet.private_subnet_a.availability_zone, aws_subnet.private_subnet_b.availability_zone]
  snapshot_retention_limit    = var.valkey_snapshot_retention_limit
  snapshot_window             = var.valkey_snapshot_window
  maintenance_window          = var.valkey_maintenance_window

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  # Logging
  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.valkey_slow_log.name
    destination_type = "cloudwatch-logs"
    log_format       = "text"
    log_type         = "slow-log"
  }

  tags = {
    Name    = "mavis-cache-${var.environment}"
    Purpose = "sidekiq-job-processing"
  }
}

resource "aws_elasticache_parameter_group" "valkey" {
  family = "valkey8"
  name   = "mavis-cache-params-${var.environment}"

  # Optimize for Sidekiq workload
  parameter {
    name  = "maxmemory-policy"
    value = "noeviction" #TODO: Optimize for sidekiq
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
