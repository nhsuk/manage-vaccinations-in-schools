{
  "family": "mavis-<SERVER_TYPE>-task-definition-<ENV>",
  "containerDefinitions": [
    {
      "name": "application",
      "image": "REPOSITORY_URI",
      "portMappings": [
        {
          "containerPort": 4000,
          "protocol": "tcp"
        }
      ],
      "essential": true,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "mavis-<ENV>-ecs",
          "awslogs-region": "eu-west-2",
          "awslogs-stream-prefix": "<ENV>-<SERVER_TYPE>-logs"
        }
      },
      "healthCheck": {
        "command": [
          "CMD-SHELL",
          "./bin/internal_healthcheck http://localhost:4000<HEALTH_CHECK_PATH>"
        ],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 10
      },
      "environment": [
        {
          "name": "MAVIS__GIVE_OR_REFUSE_CONSENT_HOST",
          "value": "<MAVIS__GIVE_OR_REFUSE_CONSENT_HOST>"
        },
        {
          "name": "RAILS_ENV",
          "value": "<RAILS_ENV>"
        },
        {
          "name": "MAVIS__SPLUNK__ENABLED",
          "value": "<SPLUNK__ENABLED>"
        },
        {
          "name": "MAVIS__HOST",
          "value": "<MAVIS__HOST>"
        },
        {
          "name": "MAVIS__CIS2__ENABLED",
          "value": "<CIS2__ENABLED>"
        },
        {
          "name": "SERVER_TYPE",
          "value": "<SERVER_TYPE>"
        },
        {
          "name": "DB_NAME",
          "value": "<DB_NAME>"
        },
        {
          "name": "DB_HOST",
          "value": "<DB_HOST>"
        },
        {
          "name": "SENTRY_ENVIRONMENT",
          "value": "<ENV>"
        },
        {
          "name": "APP_VERSION",
          "value": "<APP_VERSION>"
        }
      ],
      "secrets": [
        {
          "name": "DB_CREDENTIALS",
          "valueFrom": "<DB_SECRET_ARN>"
        },
        {
          "name": "RAILS_MASTER_KEY",
          "valueFrom": "<RAILS_MASTER_KEY_ARN>"
        },
        {
          "name": "GOOD_JOB_MAX_THREADS",
          "valueFrom": "<GOOD_JOB_MAX_THREADS_ARN>"
        },
        {
          "name": "MAVIS__PDS__ENQUEUE_BULK_UPDATES",
          "valueFrom": "<MAVIS__PDS__ENQUEUE_BULK_UPDATES_ARN>"
        },
        {
          "name": "MAVIS__PDS__WAIT_BETWEEN_JOBS",
          "valueFrom": "<MAVIS__PDS__WAIT_BETWEEN_JOBS_ARN>"
        }
      ]
    }
  ],
  "taskRoleArn": "<TASK_ROLE_ARN>",
  "executionRoleArn": "<EXECUTION_ROLE_ARN>",
  "networkMode": "awsvpc",
  "requiresCompatibilities": [
    "FARGATE"
  ],
  "cpu": "<CPU>",
  "memory": "<MEMORY>",
  "tags": [
    {
      "key": "Environment",
      "value": "<ENV>"
    }
  ]
}
