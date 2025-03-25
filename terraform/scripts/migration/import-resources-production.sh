#!/usr/bin/env bash

# This script is used to import resources that were created by AWS copilot into the terraform state file.
# Add the resource IDs to the variables below before running the script.
vpc_id=vpc-0abccf7c5d1538d12
vpc_flowlogs_id=fl-0ffc19b8e05e30452
public_subnet_a_id=subnet-0940d603d2548dfbf
public_subnet_b_id=subnet-07a327947f14cf8eb
private_subnet_a_id=subnet-0267e72654e7509e3
private_subnet_b_id=subnet-003fa5711be9ce22d
public_route_table_id=rtb-072cfee19426f8f39
internet_gateway_id=igw-02952baef5ce61c57
lb_arn=arn:aws:elasticloadbalancing:eu-west-2:820242920762:loadbalancer/app/mavis-production-pub-lb/b657a6f31e2db8a6
http_listener_arn=arn:aws:elasticloadbalancing:eu-west-2:820242920762:listener/app/mavis-production-pub-lb/b657a6f31e2db8a6/ffb800ea03ede9a6
https_listener_arn=arn:aws:elasticloadbalancing:eu-west-2:820242920762:listener/app/mavis-production-pub-lb/b657a6f31e2db8a6/94617d73c392dda4
lb_http_security_group_id=sg-09bccd4e1cf368457
db_cluster_id=mavis-production-addonsstack-h6b1986bq-dbdbcluster-actkuhui4ce7
db_instance_id=mavis-production-addonsstack-h6-dbdbwriterinstance-l8rqm5mbgilx
rds_sg_id=sg-087d77eed0131b971
db_subnet_id=mavis-production-addonsstack-h6b1986bq928-dbdbsubnetgroup-1dpsuyglv1es
cloudwatch_vpc_log_group_name=mavis-production-FlowLogs

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
