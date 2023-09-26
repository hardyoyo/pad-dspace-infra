#!/bin/bash

set -euo pipefail

# Set default values for variables (can override each by setting them in the
# environment)
export DSPACE_WORKSPPACE="${HOME}/dspace-workspace"
export BACKEND_SRC="${DSPACE_WORKSPPACE}/dspace/docker-compose-cdl.yml"
export FRONTEND_SRC="${DSPACE_WORKSPPACE}/dspace-angular/docker/docker-compose-cdl-dist.yml"
export DSPACE_VER="${DSPACE_VER:-7.6}"
export AWS_PROFILE="${AWS_PROFILE:-cdl-pad-dev}"
export REGION="${REGION:-us-west-2}"
export ACCT="${ACCT:-866216109762}"
#TODO: figure out the proper default image names for these
export BACKEND_IMAGE="${BACKEND_IMAGE:-backend}"
export FRONTEND_IMAGE="${FRONTEND_IMAGE:-frontend}"
export OTHER_IMAGES="${OTHER_IMAGES:-dspace/dspace-solr:${DSPACE_VER:-latest}}" # note that these images will be pushed to ECR, but not built, handy for copying images from DockerHub, etc.

echo "===== Building Docker images for DSpace using Docker Compose ====="
docker-compose -f $BACKEND_SRC -f $FRONTEND_SRC build --pull $BACKEND_IMAGE $FRONTEND_IMAGE $OTHER_IMAGES
docker tag $BACKEND_IMAGE:latest $ACCT.dkr.ecr.$REGION.amazonaws.com/$BACKEND_IMAGE:latest
docker tag $FRONTEND_IMAGE:latest $ACCT.dkr.ecr.$REGION.amazonaws.com/$FRONTEND_IMAGE:latest

echo "===== Scanning for vulnerabilities ====="
trivy --severity critical,high image --exit-code 1 --quiet --scanners vuln --ignore-unfixed $BACKEND_IMAGE:latest $FRONTEND_IMAGE:latest $OTHER_IMAGES

echo "===== Logging in to AWS ECR ====="
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCT.dkr.ecr.$REGION.amazonaws.com

echo "===== Pushing images to ECR ====="
docker push $ACCT.dkr.ecr.$REGION.amazonaws.com/${BACKEND_IMAGE}:latest
docker push $ACCT.dkr.ecr.$REGION.amazonaws.com/${FRONTEND_IMAGE}:latest

for image in $OTHER_IMAGES; do
  docker push $ACCT.dkr.ecr.$REGION.amazonaws.com/${image}:latest
done

echo "===== Build complete ====="