#!/usr/bin/env bash

sha=$(git rev-parse HEAD)
ecr_hostname="393416225559.dkr.ecr.eu-west-2.amazonaws.com"
image="$ecr_hostname/mavis/webapp:$sha"
aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin $ecr_hostname
docker build --platform=linux/x86_64 -t $image .
docker push $image
