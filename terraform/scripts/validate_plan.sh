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
"aws_ecs_service\.service" #TODO: Remove after release
"aws_security_group\.ecs_service_sg" #TODO: Remove after release
"module\.[^.]+\.aws_ecs_service\.this"
"module\.[^.]+\.aws_security_group"
)

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <var-file>"
    exit 1
fi

tfstdout=$1

for resource in "${down_time_if_destroyed[@]}"; do
  if [[ $(grep -cE "$resource.*(replaced|destroyed)" "$tfstdout") -ne 0 ]]; then
    echo -e "\e[41mPOTENTIALLY CRITICAL RESOURCES ARE BEING DESTROYED:\e[0m"
    grep -E "$resource.*(replaced|destroyed)" "$tfstdout"
    echo "Check carefully if this would cause a downtime"
    exit 0
  fi
done

echo -e "\e[32mNo obvious downtime-relevant changes detected.\e[0m"
