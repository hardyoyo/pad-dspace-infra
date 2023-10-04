#!/bin/bash

set -euo pipefail
# set -x  # uncomment to enable debugging

# PREREQUISITES
# you must create repositories in ECR for each image you want to push. Do this on the console:
# https://us-west-2.console.aws.amazon.com/ecr/repositories?region=us-west-2


#TODO: we'll need the CLI image eventually, add it to OTHER_IMAGES

# Set default values for variables (can override each by setting them in the
# environment)
export DSPACE_VERSION_NUMBER="${DSPACE_VERSION_NUMBER:-7.6}"
export DSPACE_VER="dspace-${DSPACE_VERSION_NUMBER}"
export DSPACE_WORKSPACE="${HOME}/dspace-workspace"
export BACKEND_SRC="${DSPACE_WORKSPACE}/dspace/docker-compose-cdl.yml"
export FRONTEND_SRC="${DSPACE_WORKSPACE}/dspace-angular/docker/docker-compose-cdl-dist.yml"
export AWS_PROFILE="cdl-pad-dev"
export REGION="${REGION:-us-west-2}"
export ACCT="${ACCT:-866216109762}"
export BACKEND_IMAGE="${BACKEND_IMAGE:-dspace/dspace}"
export FRONTEND_IMAGE="${FRONTEND_IMAGE:-cdl/dspace-angular}"
export BACKEND_IMAGE_TAG="${DSPACE_VER:-latest}"
export FRONTEND_IMAGE_TAG="cdl-latest-dist"
export OTHER_IMAGES="${OTHER_IMAGES:-dspace/dspace-solr:${BACKEND_IMAGE_TAG:-latest}}" # note that these images will be pushed to ECR, but not built, handy for copying images from DockerHub, etc.

echo "==== Pulling Docker images to our local repository ===="
for image in $OTHER_IMAGES; do
    docker pull ${image} # note that images all should include tags
done

# save this for later, skip building for now

# echo "==== Building Docker images for DSpace using Docker Compose ===="
# docker-compose -f $BACKEND_SRC -f $FRONTEND_SRC build

echo "==== Tagging Docker images so they can be pushed ===="
#docker tag image:tag $ACCT.dkr.ecr.$REGION.amazonaws.com/image:tag
for image in $BACKEND_IMAGE:$BACKEND_IMAGE_TAG $FRONTEND_IMAGE:$FRONTEND_IMAGE_TAG $OTHER_IMAGES; do
	docker tag ${image} $ACCT.dkr.ecr.$REGION.amazonaws.com/${image}
done

echo "==== Logging in to AWS ECR ===="
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCT.dkr.ecr.$REGION.amazonaws.com

echo "==== Pushing images to ECR ===="
# docker push $ACCT.dkr.ecr.$REGION.amazonaws.com/${BACKEND_IMAGE}:${BACKEND_IMAGE_TAG}
# docker push $ACCT.dkr.ecr.$REGION.amazonaws.com/${FRONTEND_IMAGE}:${FRONTEND_IMAGE_TAG}
for image in $BACKEND_IMAGE:$BACKEND_IMAGE_TAG $FRONTEND_IMAGE:$FRONTEND_IMAGE_TAG $OTHER_IMAGES; do
	docker push $ACCT.dkr.ecr.$REGION.amazonaws.com/${image}
done

echo "==== Build complete ===="
exit 0
