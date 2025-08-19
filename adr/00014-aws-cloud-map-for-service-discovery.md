# 14. Use AWS Cloud Map for Service Discovery

Date: 2025-07-21

## Status

Accepted

## Context

The introduction of the reporting service transforms the Mavis application into one consisting of multiple ECS
services that need to communicate with each other internally, for data access and processing. Therefore, we require a
scalable and reliable service discovery mechanism to facilitate this architectural change.

## Considered Options

Several service discovery approaches were evaluated for ECS inter-service communication, prioritizing CodeDeploy
compatibility for blue-green deployments and scalability for future services.

### Option 1: Internal Application Load Balancer (ALB)

Use an internal ALB for routing via path/host rules, with ECS-integrated target groups for dynamic registration.

- **Pros**: Includes load balancing and health checks.
- **Cons**: Incompatible with CodeDeploy's task set management (max one target group per ECS service);
  adds SSL and rule overhead.

Rejected due to deployment issues.

### Option 2: AWS Service Connect

Managed ECS discovery with DNS, load balancing, and metrics, built on Cloud Map.

- **Pros**: Easy setup with failover and telemetry; implementing TLS/SSL is straightforward.
- **Cons**: Requires ECS controller, conflicting with CodeDeploy's blue-green needs.

Rejected for compatibility.

### Option 3: AWS Cloud Map (Service Discovery)

Register services in a private DNS namespace for resolution (e.g., `web.mavis.${environment}.aws-int`), using MULTIVALUE
routing.

- **Pros**: CodeDeploy-compatible; lightweight DNS-based; ECS-integrated registration.
- **Cons**: No built-in load balancing; needs manual security rules; implementing TLS/SSL requires additional complexity

Selected for meeting requirements.

### Comparison

With the requirement of blue-green deployments, AWS Cloud Map was the only viable option that offered a simple DNS-based
service discovery mechanism that integrates well with ECS and CodeDeploy.

## Decision

We will use AWS Cloud Map (Service Discovery) to enable service-to-service communication. This involves creating a
private DNS namespace within the VPC and registering ECS services (e.g., the web service) with Cloud Map. Services can
then resolve each other using DNS names (e.g., `web.mavis.${environment}.aws-int`), allowing dynamic IP resolution for
tasks.

- A private DNS namespace (`mavis.${environment}.aws-int`) will be provisioned.
- The web service will be registered with a MULTIVALUE routing policy to support multiple tasks.
- Security group rules will explicitly allow ingress/egress between services
  (e.g., reporting service to web service on port 4000).
- This integrates seamlessly with Terraform for infrastructure management and does not conflict with CodeDeploy.

## Consequences

- Services will dynamically discover each other via DNS, improving scalability and reducing configuration drift.
- Additional Terraform resources (e.g., `aws_service_discovery_private_dns_namespace` and
  `aws_service_discovery_service`) will be maintained, increasing infrastructure complexity slightly but providing
  better automation.
- DNS caching (TTL set to 10 seconds initially) may introduce minor latency during task scaling or failures; this can be
  tuned based on monitoring.
- Alignment with AWS-native services ensures compatibility with future enhancements but requires monitoring DNS
  resolution metrics to detect issues.
- No changes to application code are needed beyond using the resolved DNS names for internal calls.
