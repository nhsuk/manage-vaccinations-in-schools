#!/usr/bin/env bash

# This script is used to import resources that were created by AWS copilot into the terraform state file.
# Add the resource IDs to the variables below before running the script.
vpc_id=vpc-0016fa51fbdfbf86e
vpc_flowlogs_id=fl-08bd5f251fe92d277
public_subnet_a_id=subnet-0e45214d2940ef9a8
public_subnet_b_id=subnet-078685f75042efd82
private_subnet_a_id=subnet-0522dade9bd8d11e5
private_subnet_b_id=subnet-00fa7ee1070eab45c
public_route_table_id=rtb-09b0d6376e48cd653
internet_gateway_id=igw-01ce736d4aa6040f2
lb_arn=arn:aws:elasticloadbalancing:eu-west-2:393416225559:loadbalancer/app/mavis--Publi-w1wzc4E2jrl6/b953a35af361bbf6
http_listener_arn=arn:aws:elasticloadbalancing:eu-west-2:393416225559:listener/app/mavis--Publi-w1wzc4E2jrl6/b953a35af361bbf6/fd25d4042ac43a15
https_listener_arn=arn:aws:elasticloadbalancing:eu-west-2:393416225559:listener/app/mavis--Publi-w1wzc4E2jrl6/b953a35af361bbf6/d21186d3d971fe1f
lb_http_security_group_id=sg-03d88bf5572e8790d
db_cluster_id=mavis-training-addonsstack-1jzsxp7p842-dbdbcluster-dojxjwailzmh
db_instance_id=mavis-training-addonsstack-1jzs-dbdbwriterinstance-pbl8rjktgtmp
rds_sg_id=sg-044c5b666b01ebb1e
db_subnet_id=mavis-training-addonsstack-1jzsxp7p84221-dbdbsubnetgroup-ybdt5wfbx9jl
cloudwatch_vpc_log_group_name=mavis-training-FlowLogs

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <var-file>"
    exit 1
fi
VAR_FILE="$1"
IMPORT_COUNT=0
IMPORT_RESOURCES=(
  "aws_vpc.application_vpc $vpc_id"
  "aws_flow_log.vpc_flowlogs $vpc_flowlogs_id"
  "aws_subnet.public_subnet_a $public_subnet_a_id"
  "aws_subnet.public_subnet_b $public_subnet_b_id"
  "aws_subnet.private_subnet_a $private_subnet_a_id"
  "aws_subnet.private_subnet_b $private_subnet_b_id"
  "aws_route_table.public_route_table $public_route_table_id"
  "aws_route_table_association.public_a $public_subnet_a_id/$public_route_table_id"
  "aws_route_table_association.public_b $public_subnet_b_id/$public_route_table_id"
  "aws_internet_gateway.internet_gateway $internet_gateway_id"
  "aws_route.igw_route ${public_route_table_id}_0.0.0.0/0"
  "aws_lb.app_lb $lb_arn"
  "aws_lb_listener.app_listener_http $http_listener_arn"
  "aws_lb_listener.app_listener_https $https_listener_arn"
  "aws_security_group.lb_service_sg $lb_http_security_group_id"
  "aws_security_group_rule.lb_ingress_http ${lb_http_security_group_id}_ingress_tcp_80_80_0.0.0.0/0"
  "aws_rds_cluster.aurora_cluster $db_cluster_id"
  "aws_rds_cluster_instance.aurora_instance $db_instance_id"
  "aws_security_group.rds_security_group $rds_sg_id"
  "aws_db_subnet_group.aurora_subnet_group $db_subnet_id"
  "aws_cloudwatch_log_group.vpc_log_group $cloudwatch_vpc_log_group_name"
)

cd ../../app || { echo "Could not cd into app directory, no resources were imported"; exit 1; }

for resource in "${IMPORT_RESOURCES[@]}"; do
  read -r address resource_id <<< "$resource"
  terraform import -var-file="$VAR_FILE" "$address" "$resource_id" && ((IMPORT_COUNT++)) || echo "Import of $resource failed"
done


echo "Imported $IMPORT_COUNT of ${#IMPORT_RESOURCES[@]} resources successfully"
