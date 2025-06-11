module "dms_custom_kms_migration" {
  source      = "./modules/dms"
  environment = var.environment

#  The module creates a VPC endpoint for DMS to access AWS Secrets Manager, as a result we need to update ECS security groups to allow access to the endpoint.
  ecs_sg_ids            = concat(<security groups for ECS services in VPC>, [module.prepare_new_db_service.security_group_id])
  source_endpoint       = aws_rds_cluster.<source rds identifier>.endpoint
  source_port           = aws_rds_cluster.<source rds identifier>.port
  source_database_name  = aws_rds_cluster.<source rds identifier>.database_name
  source_db_secret_arn  = <DB secret ARN for source RDS cluster>

  target_endpoint      = aws_rds_cluster.<target rds identifier>.endpoint
  target_port          = aws_rds_cluster.<target rds identifier>.port
  target_database_name = aws_rds_cluster.<target rds identifier>.database_name
  target_db_secret_arn = aws_rds_cluster.<target rds identifier>.master_user_secret[0].secret_arn

  engine_name = aws_rds_cluster.<source rds identifier>.engine
  subnet_ids  = <list of private subnet IDs in which the Source and Target RDS clusters are deployed>

  rds_cluster_security_group_id = aws_security_group.rds_security_group.id
  vpc_id                        = <VPC in which source RDS cluster is deployed>
}

module "prepare_new_db_service" {
  source = "./modules/ecs_service"

  cluster_id            = aws_ecs_cluster.cluster.id
  cluster_name          = aws_ecs_cluster.cluster.name
  environment           = var.environment
  maximum_replica_count = 1
  minimum_replica_count = 1
  network_params = {
    subnets = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
    vpc_id  = <VPC in which source RDS cluster is deployed>
  }
  server_type      = "none"
  server_type_name = "prepare_new_db"
  task_config = {
    environment = [{
      name  = "DB_HOST"
      value = aws_rds_cluster.<target rds identifier>.endpoint
    },
      {
        name  = "DB_NAME"
        value = aws_rds_cluster.<target rds identifier>.database_name
      },
      {
        name  = "RAILS_ENV"
        value = var.rails_env
      },
      {
        name  = "SENTRY_ENVIRONMENT"
        value = var.environment
      },
      {
        name  = "MAVIS__CIS2__ENABLED"
        value = "false"
      },
      {
        name  = "MAVIS__SPLUNK__ENABLED"
        value = "false"
      }
    ]
    secrets = [
      {
        name      = "DB_CREDENTIALS"
        valueFrom = aws_rds_cluster.<target rds identifier>.master_user_secret[0].secret_arn
      },
      {
        name      = "RAILS_MASTER_KEY"
        valueFrom = var.rails_master_key_path
      }
    ]
    cpu                  = 1024
    memory               = 2048
    docker_image         = "${var.account_id}.dkr.ecr.eu-west-2.amazonaws.com/${var.docker_image}@${var.image_digest}"
    execution_role_arn   = <ecs task execution role ARN used by existing ECS services (with access to RAILS key)>
    task_role_arn        = <ecs task role ARN used by existing ECS services (with access to RAILS key)>
    log_group_name       = <aws_cloudwatch_log_group.ecs_log_group.name>
    region               = var.region
    health_check_command = ["CMD-SHELL", "echo 'alive' || exit 1"]
  }
}

resource "aws_security_group_rule" "db_prepare_access_to_db" {
  type                     = "ingress"
  from_port                = aws_rds_cluster.<target rds identifier>.port
  to_port                  = aws_rds_cluster.<target rds identifier>.port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_security_group.id
  source_security_group_id = module.prepare_new_db_service.security_group_id

  description = "Allow access from the prepare_new_db ECS service to the target RDS cluster"
}
