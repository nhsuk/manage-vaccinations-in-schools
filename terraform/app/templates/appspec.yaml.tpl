# This is an appspec.yml template file for use with an Amazon ECS deployment in CodeDeploy.
# The lines in this template that start with the hashtag are
#   comments that can be safely left in the file or
#   ignored.
# For help completing this file, see the "AppSpec File Reference" in the
#   "CodeDeploy User Guide" at
#   https://docs.aws.amazon.com/codedeploy/latest/userguide/app-spec-ref.html
version: 0.0
Resources:
  - TargetService:
      Type: AWS::ECS::Service
      Properties:
        TaskDefinition: "${task_definition_arn}"
        LoadBalancerInfo:
          ContainerName: "${container_name}"
          ContainerPort: "${container_port}"
