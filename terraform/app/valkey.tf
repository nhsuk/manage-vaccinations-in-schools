resource "aws_security_group" "reporting_valkey" {
  name        = "mavis-cache-${var.environment}"
  description = "Security group for Valkey ElastiCache for the reporting service"
  vpc_id      = aws_vpc.application_vpc.id

  tags = {
    Name = "mavis-cache-${var.environment}"
  }

  lifecycle {
    ignore_changes = [description]
  }
}

resource "aws_security_group_rule" "reporting_valkey_ingress" {
  type                     = "ingress"
  from_port                = aws_elasticache_serverless_cache.reporting_service.endpoint[0].port
  to_port                  = aws_elasticache_serverless_cache.reporting_service.endpoint[0].port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.reporting_valkey.id
  source_security_group_id = module.reporting_service.security_group_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elasticache_serverless_cache" "reporting_service" {
  engine = "valkey"
  name   = "mavis-reporting-${var.environment}"
  cache_usage_limits {
    data_storage {
      maximum = 1
      unit    = "GB"
    }
    ecpu_per_second {
      maximum = 1000
    }
  }
  kms_key_id           = aws_kms_key.reporting_valkey.arn
  major_engine_version = "8"
  security_group_ids   = [aws_security_group.reporting_valkey.id]
  subnet_ids           = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
}