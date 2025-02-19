#!/usr/bin/env bash

down_time_if_destroyed=(
"aws_vpc\.application_vpc"
"aws_subnet\.public_subnet_a"
"aws_subnet\.public_subnet_b"
"aws_subnet\.private_subnet_a"
"aws_subnet\.private_subnet_b"
"aws_route_table\.public_route_table"
"aws_route_table\.private_route_table"
"aws_route_table_association\.public_a"
"aws_route_table_association\.public_b"
"aws_route_table_association\.private_a"
"aws_route_table_association\.private_b"
"aws_internet_gateway\.internet_gateway"
"aws_route\.igw_route"
"aws_lb\.app_lb"
"aws_lb_listener\.app_listener_http"
"aws_lb_listener\.app_listener_https"
"aws_security_group\.lb_service_sg"
"aws_rds_cluster\.aurora_cluster"
"aws_rds_cluster_instance\.aurora_instance"
"aws_security_group\.rds_security_group"
"aws_db_subnet_group\.aurora_subnet_group"
"aws_ecs_cluster\.cluster"
"aws_ecs_service\.service"
"aws_security_group\.ecs_service_sg"
)

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <var-file>"
    exit 1
fi

tfstdout=$1

for resource in "${down_time_if_destroyed[@]}"; do
  if [[ $(grep -cE "$resource.*(replaced|destroyed)" "$tfstdout") -ne 0 ]]; then
    echo "$resource is being destroyed. This would cause a downtime. Aborting"
    exit 1
  fi
done

echo "No obvious downtime-relevant changes detected. Proceeding with the plan."
