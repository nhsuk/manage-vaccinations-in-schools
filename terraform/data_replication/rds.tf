resource "aws_db_subnet_group" "dbsg" {
  name       = "${local.name_prefix}-subnet-group"
  subnet_ids = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
}

resource "aws_security_group" "rds" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_security_group_rule" "rds_inbound" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = module.db_access_service.security_group_id
}

resource "aws_rds_cluster" "cluster" {
  cluster_identifier     = "${local.name_prefix}-rds-${formatdate("hh-mm-ss", timestamp())}"
  engine                 = "aurora-postgresql"
  engine_mode            = "provisioned"
  database_name          = "manage_vaccinations"
  master_username        = "postgres"
  snapshot_identifier    = local.imported_snapshot_identifier
  db_subnet_group_name   = aws_db_subnet_group.dbsg.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  storage_encrypted      = true
  skip_final_snapshot    = true
  deletion_protection    = false
  engine_version         = var.db_engine_version

  serverlessv2_scaling_configuration {
    max_capacity = var.max_aurora_capacity_units
    min_capacity = 0.5
  }

  lifecycle {
    ignore_changes = [cluster_identifier]
  }

  depends_on = [null_resource.validate_snapshot]
}

resource "aws_rds_cluster_instance" "instance" {
  cluster_identifier   = aws_rds_cluster.cluster.id
  identifier           = "${local.name_prefix}-rds-instance-${formatdate("hh-mm-ss", timestamp())}"
  instance_class       = "db.serverless"
  engine               = aws_rds_cluster.cluster.engine
  engine_version       = aws_rds_cluster.cluster.engine_version
  db_subnet_group_name = aws_db_subnet_group.dbsg.name
  promotion_tier       = 1

  lifecycle {
    ignore_changes = [identifier]
  }
}

# Validate snapshot has sanitized=true tag
data "aws_db_cluster_snapshot" "imported" {
  db_cluster_snapshot_identifier = local.imported_snapshot_identifier
}

locals {
  snapshot_tags_map = { for t in data.aws_db_cluster_snapshot.imported.tags : t.key => t.value }
  snapshot_is_sanitized = try(data.aws_db_cluster_snapshot.imported.tags["sanitized"] == "true", false)
}

resource "null_resource" "validate_snapshot" {
  triggers = {
    id        = data.aws_db_cluster_snapshot.imported.id
    sanitized = tostring(local.snapshot_is_sanitized)
  }

  provisioner "local-exec" {
    when    = create
    command = "[ \"${local.snapshot_is_sanitized}\" = \"true\" ] || { echo 'Snapshot must have tag sanitized=true'; exit 1; }"
  }
}
