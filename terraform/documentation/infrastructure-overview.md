# Infrastructure overview

## VPC Setup

The infrastructure for this service is bundled inside a VPC. It has 2 availability zones, each one with a private and a
public subnet.

## ECS Service

The core of this configuration are two ECS Fargate services. One service is running the webapp and the other one runs the background jobs.
Both are running inside private subnets. The webapp service is accessible through a load balancer.
The services contain ECS tasks, which run a docker image of the app. All services use autoscaling with a minimum of
2 tasks in production to ensure high availability.

## Database

The service uses an Aurora Serverless RDS Database. It can be accessed only from within the private subnets.

## NAT Gateway

A NAT Gateway exists to enable outgoing traffic from the services.

## CodeDeploy

CodeDeploy is used to manage the app deployments without downtime. For more information about the deployment process
see [deployment-process.md](./deployment-process.md)
