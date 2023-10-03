#!/bin/bash

set -euo pipefail

# Set default values for variables (can override each by setting them in the
# environment)
export DSPACE_VERSION_NUMBER="${DSPACE_VERSION_NUMBER:-7.6}"
export DSPACE_VER="dspace-${DSPACE_VERSION_NUMBER}"
export DSPACE_WORKSPACE="${HOME}/dspace-workspace"
export BACKEND_SRC="${DSPACE_WORKSPACE}/dspace/docker-compose-cdl.yml"
export FRONTEND_SRC="${DSPACE_WORKSPACE}/dspace-angular/docker/docker-compose-cdl-dist.yml"
export AWS_PROFILE="${AWS_PROFILE:-cdl-pad-dev}"
export REGION="${REGION:-us-west-2}"
export ACCT="${ACCT:-866216109762}"
export BACKEND_IMAGE="${BACKEND_IMAGE:-dspace/dspace}"
export FRONTEND_IMAGE="${FRONTEND_IMAGE:-cdl/dspace-angular}"
export BACKEND_IMAGE_TAG="${DSPACE_VER:-latest}"
export FRONTEND_IMAGE_TAG="cdl-latest-dist}"
export OTHER_IMAGES="${OTHER_IMAGES:-dspace/dspace-solr:${BACKEND_IMAGE_TAG:-latest}}" # note that these images will be pushed to ECR, but not built, handy for copying images from DockerHub, etc.

echo "===== Building Docker images for DSpace using Docker Compose ====="
docker-compose -f $BACKEND_SRC -f $FRONTEND_SRC build --pull $BACKEND_IMAGE:$BACKEND_IMAGE_TAG $FRONTEND_IMAGE:$FRONTENMD_IMAGE_TAG $OTHER_IMAGES

echo "===== Pushing built images to ECR ====="
docker push $ACCT.dkr.ecr.$REGION.amazonaws.com/${BACKEND_IMAGE}:${FRONTEND_IMAGE_TAG}
docker push $ACCT.dkr.ecr.$REGION.amazonaws.com/${FRONTEND_IMAGE}:${BACKEND_IMAGE_TAG}

for image in $OTHER_IMAGES; do
    docker push $ACCT.dkr.ecr.$REGION.amazonaws.com/${image}:${BACKEND_IMAGE_TAG}
done

echo "===== Build complete ====="
exit 0
