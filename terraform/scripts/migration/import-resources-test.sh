#!/usr/bin/env bash

# This script is used to import resources that were created by AWS copilot into the terraform state file.
# Add the resource IDs to the variables below before running the script.
vpc_id=vpc-029e1475034ab2fed
vpc_flowlogs_id=fl-0a499764d95305abb
public_subnet_a_id=subnet-0cf32ca58b4ec23b4
public_subnet_b_id=subnet-07741dd5bc32f0268
private_subnet_a_id=subnet-0c74e12af3b2ec3bf
private_subnet_b_id=subnet-026b606d9f4b82f4a
public_route_table_id=rtb-0b5a19796947bf52d
internet_gateway_id=igw-0c608bba7dad82438
lb_arn=arn:aws:elasticloadbalancing:eu-west-2:393416225559:loadbalancer/app/mavis--Publi-W19xy2QLULZ4/ee53c8d5372e883c
http_listener_arn=arn:aws:elasticloadbalancing:eu-west-2:393416225559:listener/app/mavis--Publi-W19xy2QLULZ4/ee53c8d5372e883c/ed4a2767f82ef328
https_listener_arn=arn:aws:elasticloadbalancing:eu-west-2:393416225559:listener/app/mavis--Publi-W19xy2QLULZ4/ee53c8d5372e883c/e804041151f929d4
lb_http_security_group_id=sg-03a1b557ec8f84abe
db_cluster_id=mavis-test-addonsstack-gb8z9lqvo8of-dbdbcluster-0ed2hxoxu1v1
db_instance_id=mavis-test-addonsstack-gb8z9lqv-dbdbwriterinstance-mq40ycdtxcan
rds_sg_id=sg-00c46c1f9a5949f18
db_subnet_id=mavis-test-addonsstack-gb8z9lqvo8of-dbdbsubnetgroup-8hrfkmuyp4c4
cloudwatch_vpc_log_group_name=mavis-test-FlowLogs

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
