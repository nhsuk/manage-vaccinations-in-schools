#!/usr/bin/env bash
#
# This script adds a "DeletionPolicy: Retain" to the required resources in the CloudFormation stacks.
# Usage: ./add-deletion-policy.sh <yaml_file> <addonstack|environmentstack>
# The new file is saved as <addonstack|environmentstack>-with-deletion-policy.yaml

addonstack_resources=(
"dbAuroraSecret"
"dbDBCluster"
"dbDBClusterParameterGroup"
"dbDBClusterSecurityGroup"
"dbDBClusterSecurityGroupIngressFromWorkload"
"dbDBSubnetGroup"
"dbDBWriterInstance"
"dbSecretAuroraClusterAttachment"
)

environmentstack_resources=(
"AddonsStack"
"DefaultPublicRoute"
"HTTPListener"
"HTTPSListener"
"InternetGateway"
"InternetGatewayAttachment"
"PrivateSubnet1"
"PrivateSubnet2"
"PublicHTTPLoadBalancerSecurityGroup"
"PublicLoadBalancer"
"PublicRouteTable"
"PublicSubnet1"
"PublicSubnet1RouteTableAssociation"
"PublicSubnet2"
"PublicSubnet2RouteTableAssociation"
"VPC"
"VpcFlowLogGroup"
)

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <yaml_file> <addonstack|environmentstack>"
  exit 1
fi

if [ "$2" = 'addonstack' ]; then
  resources=("${addonstack_resources[@]}")
elif [ "$2" = 'environmentstack' ]; then
  resources=("${environmentstack_resources[@]}")
else
  echo "Usage: $0 <yaml_file> <addonstack|environmentstack>"
  echo "Invalid stack name, must be 'addonstack' or 'environmentstack'."
  exit 1
fi

yaml_file="$1"
target_file="$2"-with-deletion-policy.yaml
cp "$yaml_file" "$target_file"

for resource in "${resources[@]}"; do
  # 1) Look for a line exactly matching two spaces + resource + colon (e.g.: "  MyResource:")
  if grep -qE "^  ${resource}:$" "$target_file"; then
    # 2) Insert it with four spaces right after the resource line
    sed -i "/^  ${resource}:$/a \ \ \ \ DeletionPolicy: Retain" "$target_file"
    echo "Added 'DeletionPolicy: Retain' for resource '$resource'."
  else
    echo "Resource '$resource' not found, skipping."
  fi

done

