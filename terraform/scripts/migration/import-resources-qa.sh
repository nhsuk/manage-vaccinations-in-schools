#!/usr/bin/env bash

# This script is used to import resources that were created by AWS copilot into the terraform state file.
# Add the resource IDs to the variables below before running the script.
vpc_id=vpc-038fc6883f3d93661
vpc_flowlogs_id=fl-0f016acda08316ca5
public_subnet_a_id=subnet-0aa22d8dbf4ce207b
public_subnet_b_id=subnet-004b1d3be074c1368
private_subnet_a_id=subnet-058c536bca9b954a6
private_subnet_b_id=subnet-0513b2602f1132fcc
public_route_table_id=rtb-05889363dd69d3d28
internet_gateway_id=igw-0357ebb0c317ee3ff
lb_arn=arn:aws:elasticloadbalancing:eu-west-2:393416225559:loadbalancer/app/mavis-qa-pub-lb/b13314d26cd282f3
http_listener_arn=arn:aws:elasticloadbalancing:eu-west-2:393416225559:listener/app/mavis-qa-pub-lb/b13314d26cd282f3/162b02dc6827062b
https_listener_arn=arn:aws:elasticloadbalancing:eu-west-2:393416225559:listener/app/mavis-qa-pub-lb/b13314d26cd282f3/fa982b10f320d6f8
lb_http_security_group_id=sg-0a82ebc892f267a9b
db_cluster_id=mavis-qa-addonsstack-z0l4gx5euv3i-dbdbcluster-ysszxsdiq1ka
db_instance_id=mavis-qa-addonsstack-z0l4gx5euv-dbdbwriterinstance-sstfvcbqdcwa
rds_sg_id=sg-0afbf6f377139039b
db_subnet_id=mavis-qa-addonsstack-z0l4gx5euv3i-dbdbsubnetgroup-fgvafc16exxw
cloudwatch_vpc_log_group_name=mavis-qa-FlowLogs

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
