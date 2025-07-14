{
  "family": "mavis-<SERVER_TYPE_NAME>-task-definition-<ENV>",
  "containerDefinitions": [
    {
      "name": "application",
      "image": "<IMAGE_URI>",
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
          "awslogs-stream-prefix": "<SERVER_TYPE_NAME>-logs"
        }
      },
      "healthCheck": {
        "command": ["CMD-SHELL", "<HEALTH_CHECK>"],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 10
      },
      "environment": <ENVIRONMENT_VARIABLES>,
      "secrets": <SECRETS>
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
