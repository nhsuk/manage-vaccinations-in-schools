# Infrastructure overview

## VPC Setup

The infrastructure for this service is bundled inside a VPC. It has 2 availability zones, each one with a private and a
public subnet.

## ECS Service

The core of this configuration is an ECS Fargate service. The service is running inside the private subnet and is
accessible through a load balancer.
The service contains an ECS task, which runs a docker image of the app. The service uses autoscaling to dynamically
adapt the number of running tasks to the actual load.

## Database

The service uses an Aurora Serverless RDS Database. It can be accessed only from within the private subnets.

## VPC Endpoints

Since the ECS Service runs in a private subnet, it can't communicate to other AWS services outside the VPC by default.
This is required for

- Fetching the docker image from ECR
- Sending logs to CloudWatch
- Setting up secure shell access from a local machine with AWS SystemsManager

VPC endpoints are a way to enable resources to communicate with other AWS services without requiring a public IP. For
each of the use cases, there is a dedicated VPC endpoint which is configured by the
custom [VPC Endpoint](../app/modules/vpc_endpoint/README.md) module.

## CodeDeploy

CodeDeploy is used to manage the app deployments without downtime. For more information about the deployment process
see [deployment-process.md](./deployment-process.md)
