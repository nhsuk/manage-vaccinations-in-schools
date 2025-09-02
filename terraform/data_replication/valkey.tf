resource "aws_security_group" "valkey" {
  name        = "mavis-cache-${var.environment}-data-replication"
  description = "Security group for Valkey ElastiCache (self-designed cluster)"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "mavis-cache-${var.environment}-data-replication"
  }

  lifecycle {
    ignore_changes = [description]
  }
}

resource "aws_security_group_rule" "valkey_ecs_services_ingress" {
  type                     = "ingress"
  from_port                = local.valkey_port
  to_port                  = local.valkey_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.valkey.id
  source_security_group_id = module.db_access_service.security_group_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elasticache_subnet_group" "valkey" {
  name       = "mavis-cache-subnet-group-${var.environment}-data-replication"
  subnet_ids = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]

  tags = {
    Name = "mavis-cache-subnet-group-${var.environment}-data-replication"
  }
}

resource "aws_elasticache_replication_group" "valkey" {
  replication_group_id = "mavis-cache-${var.environment}-data-replication"
  description          = "Valkey cluster for Sidekiq"

  engine               = "valkey"
  engine_version       = "8.0"
  node_type            = "cache.t4g.small"
  port                 = local.valkey_port
  parameter_group_name = aws_elasticache_parameter_group.valkey.name

  num_cache_clusters          = 1
  subnet_group_name           = aws_elasticache_subnet_group.valkey.name
  security_group_ids          = [aws_security_group.valkey.id]
  preferred_cache_cluster_azs = [aws_subnet.subnet_a.availability_zone]
  snapshot_retention_limit    = 0

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
    Name    = "mavis-cache-${var.environment}-data-replication"
    Purpose = "sidekiq-job-processing"
  }
  apply_immediately = true
}

resource "aws_elasticache_parameter_group" "valkey" {
  family = "valkey8"
  name   = "mavis-cache-params-${var.environment}-data-replication"

  # Optimize for Sidekiq workload
  parameter {
    name  = "maxmemory-policy"
    value = "noeviction"
  }

  tags = {
    Name = "mavis-cache-params-${var.environment}-data-replication"
  }
}

resource "aws_cloudwatch_log_group" "valkey_slow_log" {
  name              = "/aws/elasticache/valkey/${var.environment}-data-replication/slow-log"
  retention_in_days = 1

  tags = {
    Name = "mavis-cache-slow-log-data-replication-${var.environment}"
  }
}

resource "aws_cloudwatch_log_group" "valkey_engine_log" {
  name              = "/aws/elasticache/valkey/${var.environment}-data-replication/engine-log"
  retention_in_days = 1

  tags = {
    Name = "mavis-cache-engine-log-data-replication-${var.environment}"
  }
}