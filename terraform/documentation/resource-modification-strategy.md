# Deployment Strategies and Processes for Terraform Managed Resources

Deployment strategies to prevent downtime or to preserve state integrity.

## Updating loadbalancer target groups (aws_lb_target_group)

### Why do we need a unique deployment process for target groups?

AWS' CodeDeploy switches which listener is attached to the blue or green target groups. Some configuration changes
prevent a target group from being updated in place (e.g. like changing protocol type). Therefore, we need to destroy the
target groups and recreate them, without destroying the listener/causing downtime.

### The deployment strategy

To prevent downtime we only want to destroy/recreate the target group which is not currently attached to the listener
and
then switch the listener over to the newly created target group. Luckily this can be done in a fairly automated way:

1. Identify which target group the listener is currently attached to (lets call this `group-1`)
2. Update the Terraform configuration of the non-listener-attached target group (e.g. `group-2`) and run
   `terraform apply`
3. Do a CodeDeploy deployment to switch the listener forwarding rule to the newly created target group
   1. After this point `group-1` will no longer attached to the service
4. Update the Terraform configuration of the remaining target group (e.g. `group-1`) and run `terraform apply`

At the end of these steps the system will be in the desired configuration

## Updating ECS service (aws_ecs_service)

### Why do we need a unique deployment process services

Some changes are only possible to achieve by recreating the service. The naive Terraform approach of deleting and
recreating the service is not possible because the service's deployment is controlled by CodeDeploy, this is a built-in
safety mechanism. Additionally even if we can circumvent this blocker to deployment recreating the service would
cause a downtime which can easily be avoided by following the below steps.

### The deployment strategy

For simplicity lets call the existing service `service-a` and the new modified service `service-b`

1. Update the terraform configuration:
   1. Create a `service-b` with the new configurations but identical loadbalancer configuration
   2. Duplicate the existing autoscaling configuration and attached it to `service-b`
   3. Update the CodeDeploy deployment group to be linked to the `service-b`
2. Run `terraform apply` to deploy the new service and update the CodeDeploy configuration
   1. This service is not yet accessible by users, as the LB listener is still pointing to `group-1`
3. Run a CodeDeploy deployment
   1. After this stage all traffic will be going to `service-b` and `service-a` will be completely disconnected
4. Remove `service-a` and the attached autoscaling configuration from the configuration and run `terraform apply`

At the end of these steps a new service will be running with the updated configuration without any downtime
