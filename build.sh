#!/bin/bash

set -euo pipefail

export AWS_PROFILE=cdl-pad-dev
export FUNC=pub-dspace-dev
export REGION=us-west-2
export ACCT=866216109762

# To defeat all docker caching, pass "--no-cache" on the command line and
# it'll get passed through on the container build step.

# TODO maybe make sure Docker Desktop is running... but it's not clear to me why
# you can use `pidof docker` to check
# # Make sure podman is running
# if ! (netstat -vanp tcp | egrep 63972 > /dev/null); then
#     echo "Podman doesn't appear to be running. Maybe do this:"
#     echo "  podman machine start"
#     exit 1
# fi

echo "===== Building Dockerfile for DSpace using Docker Desktop ====="
cd dspace && docker build --pull --build-arg CACHEBUST=$(date -Idate) $* -t $FUNC .
docker tag $FUNC:latest $ACCT.dkr.ecr.$REGION.amazonaws.com/$FUNC:latest

# FIXME: re-enable this scan after you set up the trivyignore file
# echo "===== Scanning for vulnerabilities ====="
# trivy --severity critical,high image --exit-code 1 --quiet --scanners vuln --ignore-unfixed $FUNC:latest

echo "===== Logging in to AWS ECR ====="
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCT.dkr.ecr.$REGION.amazonaws.com

echo "===== Pushing image to ECR ====="
docker push $ACCT.dkr.ecr.$REGION.amazonaws.com/${FUNC}:latest

echo "===== Build complete ====="
