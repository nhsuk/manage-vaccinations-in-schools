# Terraform Lifecycle and Permissions

Resources managed by terraform have their configuration stored in the Terraform state file (located in some S3 bucket).
For some of these configurations we want to modify or restrict how terraform behaves under configuration changes and
state drift, while for other situations we want to prevent critical resources from being modified or destroyed. This
behaviour can be achieved by a combination of lifecycle arguments and AWS permissions.

# Ignoring Changes which are managed by CodeDeploy:

`ignore_change=true`

Certain configuration updates will require a redeployment since the resources cannot be updated in place (e.g. like the
task definition used in an ECS service). Since we wish for deployments to be controlled by the CodeDeploy application
and not by terraform this means we need to tell Terraform to ignore certain changes in its deployment.

Currently, the configurations which should be managed by CodeDeploy, and which are therefore ignored in the terraform
configuration are:

1. The task_definition variable in the aws_ecs_service resrouce
   1. If you change the associated aws_ecs_task_definition the service will remain as-is but a new appspec.yaml
      is created. This file is used for CodeDeploy and will record the new configuration that should be rolled out

**IMPORTANT:**

```text
The arguments corresponding to the given attribute names are considered when planning a create operation, but are ignored when planning an update.
```

In other words, if these resources are not updated in place but destroyed before a new one is created it will apply
the configuration in the terraform file to the new instance. This is not what we want, as this may not correlate with
the current setup that has been created by CodeDeploy. Therefore, for these resources we must have safety-mechanisms
in place to prevent the destruction of resources.
This is discussed in [another section](#preventing-deletion-of-resources)

# Preventing downtime

## Resources which should never be deleted

`prevent_destroy=true`

The default mechanism to prevent resource destruction in terraform is to use the lifecycle `prevent-destroy=true`. This
may make sense for all environments for some resources (e.g. like a shared database between multiple application
instances).

However, lifecycles to do not permit terraform variables (as lifecycle blocks are evaluated before variables,
ref. [documentation](https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle#literal-values-only)).
Instead, to control this on an environment-specific basis one could use environment-scoped permissions. For example,
in Production the terraform deployment pipeline should not have delete permissions on any resources which are modified
by CodeDeploy. This means

- ECS clusters/services
- Loadbalancer configuration

Other resources, such as security groups, can normally not be deleted because Terraform does not have
information about which states are attached.
See [this Github issue](https://github.com/hashicorp/terraform-provider-aws/issues/2445) for more details.

## Resources which must always exist

`create_before_destroy=true`
In some cases it is not necessary to prevent the deletion of a resource, but simply ensuring that the resource
always exists. Terraform by default will first destroy the resource and then create its replacement. To override this
feature you can use the lifecycle `create-before-destroy=true` feature. This (as the name implies) ensures a new
instance of the resource exists before the old one is deleted.
