resource "aws_codedeploy_app" "example" {
  compute_platform = "ECS"
  name             = "blue-green-codedeploy-${var.environment}"
}

resource "aws_codedeploy_deployment_group" "blue_green_deployment_group" {
  app_name               = aws_codedeploy_app.example.name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name  = "codedeploy-group-${var.environment}"
  service_role_arn       = aws_iam_role.code_deploy.arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 1
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.cluster.name
    service_name = aws_ecs_service.service.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.app_listener_https.arn]
      }

      target_group {
        name = aws_lb_target_group.blue.name
      }

      target_group {
        name = aws_lb_target_group.green.name
      }
    }
  }
}

resource "aws_s3_bucket" "code_deploy_bucket" {
  bucket        = "appspec-bucket-${var.environment}"
  force_destroy = true
}


data "aws_s3_bucket" "logs" {
  bucket = "nhse-mavis-logs-${var.environment}"
}

resource "aws_s3_bucket_logging" "example" {
  bucket = aws_s3_bucket.code_deploy_bucket.id

  target_bucket = data.aws_s3_bucket.logs.id
  target_prefix = "codedeploy-log/"
}

resource "aws_s3_bucket_versioning" "code_deploy_bucket_versioning" {
  bucket = aws_s3_bucket.code_deploy_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "block_http" {
  bucket = aws_s3_bucket.code_deploy_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "block-http-policy"
    Statement = [
      {
        Sid       = "HTTPSOnly"
        Effect    = "Deny"
        Principal = {
          "AWS": "*"
        }
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.code_deploy_bucket.arn,
          "${aws_s3_bucket.code_deploy_bucket.arn}/*",
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "s3_bucket_access" {
  bucket                  = aws_s3_bucket.code_deploy_bucket.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "appspec_object" {
  bucket = aws_s3_bucket.code_deploy_bucket.bucket
  key    = "appspec.yaml"
  acl    = "private"
  content = templatefile("templates/appspec.yaml.tpl", {
    task_definition_arn = aws_ecs_task_definition.task_definition.arn
    container_name      = jsondecode(aws_ecs_task_definition.task_definition.container_definitions)[0].name
    container_port      = aws_lb_target_group.blue.port
  })

  tags = {
    UseWithCodeDeploy = true
  }
}
