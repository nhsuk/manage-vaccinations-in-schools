#!/usr/bin/env bash

# This script is used to import resources that were created by AWS copilot into the terraform state file.
# Add the resource IDs to the variables below before running the script.
vpc_id=vpc-087d03fc1f439f7fd
vpc_flowlogs_id=fl-00f6b02df9bc0d7cf
public_subnet_a_id=subnet-05f3f48033cc9c807
public_subnet_b_id=subnet-0feeb27677707e7b7
private_subnet_a_id=subnet-0737977967730bfe6
private_subnet_b_id=subnet-0618c27ba44bb0602
public_route_table_id=rtb-0b53f2bd12962916c
internet_gateway_id=igw-0b71e931467e38749
lb_arn=arn:aws:elasticloadbalancing:eu-west-2:393416225559:loadbalancer/app/mavis-preview-pub-lb/65464647b10c6b6c
http_listener_arn=arn:aws:elasticloadbalancing:eu-west-2:393416225559:listener/app/mavis-preview-pub-lb/65464647b10c6b6c/c898d952f858d26c
https_listener_arn=arn:aws:elasticloadbalancing:eu-west-2:393416225559:listener/app/mavis-preview-pub-lb/65464647b10c6b6c/67ef44245aa26f8d
lb_http_security_group_id=sg-0a4620da3a0cec62b
db_cluster_id=mavis-preview-addonsstack-1pd6pksn106r-dbdbcluster-lrf8p5py9wfb
db_instance_id=mavis-preview-addonsstack-1pd6p-dbdbwriterinstance-aozmqfwfm2va
rds_sg_id=sg-000eedb40d3b0cd1a
db_subnet_id=mavis-preview-addonsstack-1pd6pksn106rk-dbdbsubnetgroup-8pkydanicgra
cloudwatch_vpc_log_group_name=mavis-preview-FlowLogs

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
