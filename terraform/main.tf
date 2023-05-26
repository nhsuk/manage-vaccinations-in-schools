# These are the supported environments. These need to map to the Terraform
# workspaces.
locals {
  short_environment_names = {
    staging    = "stg"
  }
  environment_names = {
    staging    = "staging"
  }
}

locals {
  environment = lookup(local.environment_names, terraform.workspace)
}

locals {
  app_name             = "record-childrens-vaccinations"
  abbreviated_app_name = "rcv"
  region               = "eu-west-2"
  env                  = local.short_environment_names[local.environment]
  image                = "public.ecr.aws/z8i3v8n4/record-childrens-vaccinations:latest"
  db_port              = 5432
  webapp_port          = 4000

  azs                  = ["eu-west-2a", "eu-west-2b"]
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets       = ["10.0.101.0/24", "10.0.102.0/24"]
  database_subnets     = ["10.0.201.0/24", "10.0.202.0/24"]

  tags                 = {
    AppName     = local.app_name
    Environment = local.environment
    Source      = "terraform"
  }
}

locals {
  app_name_underscored = replace(local.app_name, "-", "_")
}

provider "aws" {
  region = local.region
}


data "aws_secretsmanager_secret" "rails_master_key" {
  name = "rails_master_key"
}

data "aws_secretsmanager_secret_version" "rails_master_key_latest" {
  secret_id = data.aws_secretsmanager_secret.rails_master_key.id
}

data "aws_secretsmanager_secret" "support_user_credentials" {
  name = "support_user_credentials"
}

data "aws_secretsmanager_secret_version" "support_user_credentials_latest" {
  secret_id = data.aws_secretsmanager_secret.support_user_credentials.id
}

data "aws_secretsmanager_secret_version" "db_credentials_latest" {
  secret_id = "db_credentials"
}

locals {
  db_credentials = jsondecode(data.aws_secretsmanager_secret_version.db_credentials_latest.secret_string)
  db_username    = local.db_credentials.username
  db_password    = local.db_credentials.password
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"

  name = "${local.abbreviated_app_name}-${local.env}"
  cidr = "10.0.0.0/16"

  azs               = local.azs
  private_subnets   = local.private_subnets
  public_subnets    = local.public_subnets
  database_subnets  = local.database_subnets
  create_database_subnet_group = true

  enable_nat_gateway = true
  single_nat_gateway  = true

  tags = local.tags
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"

  identifier = "${local.abbreviated_app_name}-${local.env}-db"
  apply_immediately = true

  engine            = "postgres"
  engine_version    = "13.7"
  family            = "postgres13"
  instance_class    = "db.t3.micro"
  allocated_storage = 5

  db_name                = local.app_name_underscored
  username               = local.db_username
  password               = local.db_password
  port                   = local.db_port
  create_random_password = false

  vpc_security_group_ids = [module.security_group.security_group_id]
  db_subnet_group_name   = module.vpc.database_subnet_group_name
  subnet_ids             = local.database_subnets
}

module "security_group" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "${local.abbreviated_app_name}-${local.env}-db-sg"
  description = "DB security group for ${local.app_name}"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port = local.db_port
      to_port   = local.db_port
      protocol  = "tcp"
      description = "Postgres from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    }
  ]
}

module "ecs" {
  source       = "terraform-aws-modules/ecs/aws"
  cluster_name = "${local.abbreviated_app_name}-${local.env}-cluster"

  services = {
    rails-app = {
      cpu     = 256
      memory  = 1024

      # Required to be able to ssh into the container.
      enable_execute_command = true

      # Allow us to have 0 tasks running. This service isn't running 24/7 (yet?)
      autoscaling_min_capacity = 0

      container_definitions = {
        webapp = {
          essential = true
          image     = local.image
          readonly_root_filesystem = false

          port_mappings = [
            {
              name          = "rails-app"
              containerPort = local.webapp_port
              protocol      = "tcp"
            }
          ]

          # This doesn't appear to be the right way to do this.
          # tasks_iam_role_statements = {
          #   "ecs_task_with_execute_command_role" = {
          #     Effect    = "Allow"
          #     Action    = [
          #       "ssmmessages:CreateControlChannel",
          #       "ssmmessages:CreateDataChannel",
          #       "ssmmessages:OpenControlChannel",
          #       "ssmmessages:OpenDataChannel"
          #     ],
          #     Resource  = ["*"]
          #   }
          # }

          environment = [
            {
              name  = "DATABASE_URL"
              value = "postgres://${local.db_username}:${local.db_password}@${module.db.db_instance_address}:5432/${local.app_name}"
            },
            {
              name  = "RAILS_ENV"
              value = local.environment
            },
            {
              name = "RAILS_MASTER_KEY"
              value = data.aws_secretsmanager_secret_version.rails_master_key_latest.secret_string
            },
            {
              name = "RCVAPP__SUPPORT_USERNAME"
              value = jsondecode(data.aws_secretsmanager_secret_version.support_user_credentials_latest.secret_string).username
            },
            {
              name = "RCVAPP__SUPPORT_PASSWORD"
              value = jsondecode(data.aws_secretsmanager_secret_version.support_user_credentials_latest.secret_string).password
            }
          ]
        }
      }

      subnet_ids = concat(module.vpc.private_subnets)

      load_balancer = {
        service = {
          target_group_arn = element(module.alb.target_group_arns, 0)
          container_name   = "webapp"
          container_port   = local.webapp_port
        }
      }

      security_group_rules = {
        alb_ingress_4000 = {
          type                     = "ingress"
          from_port                = local.webapp_port
          to_port                  = local.webapp_port
          protocol                 = "tcp"
          description              = "Service port"
          cidr_blocks              = ["0.0.0.0/0"]
        }
        egress_all = {
          type        = "egress"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
  }

  tags = local.tags
}

module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  # version = "~> 4.0"

  name        = "${local.abbreviated_app_name}-${local.env}-alb-sg"
  description = "Service security group"
  vpc_id      = module.vpc.vpc_id

  ingress_rules       = ["http-80-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules       = ["all-all"]
  egress_cidr_blocks = module.vpc.private_subnets_cidr_blocks

  tags = local.tags
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  # version = "~> 8.0"

  name = "${local.abbreviated_app_name}-${local.env}-alb"

  load_balancer_type = "application"

  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets
  security_groups = [module.alb_sg.security_group_id]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    },
  ]

  target_groups = [
    {
      name_prefix      = local.abbreviated_app_name
      backend_protocol = "HTTP"
      backend_port     = local.webapp_port
      target_type      = "ip"
      health_check = {
        enabled             = true
        path                = "/ping"
      }
      tags = local.tags
    },
  ]
  tags = local.tags
}

