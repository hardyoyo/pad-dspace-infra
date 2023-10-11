#!/bin/bash

set -euo pipefail
# set -x  # uncomment to enable debugging

# PREREQUISITES
# you must create repositories in ECR for each image you want to push. Do this on the console:
# https://us-west-2.console.aws.amazon.com/ecr/repositories?region=us-west-2
# or you can use the AWS CLI, e.g.:
# aws ecr create-repository --repository-name dspace/dspace-cli --region us-west-2

# detect if AWS_PROFILE is already set, and is different than the AWS_PROFILE we need to use
export REQUIRED_AWS_PROFILE="cdl-pad-dev"

if [[ -n "${AWS_PROFILE}" && "${AWS_PROFILE}" != "${REQUIRED_AWS_PROFILE}" ]]; then
  echo "WARNING: AWS_PROFILE is set to '${AWS_PROFILE}' but '${REQUIRED_AWS_PROFILE}' is required to run this script."
	echo "Resetting AWS_PROFILE to '${REQUIRED_AWS_PROFILE}'..."
	export AWS_PROFILE="${REQUIRED_AWS_PROFILE}"
	echo "AWS_PROFILE is now set to '${AWS_PROFILE}'"
	echo "We advise you to re-authenticate via 'aws sso login' to ensure you have the correct credentials for this profile."
fi

# Set default values for variables (can override each by setting them in the
# environment)
export DSPACE_VERSION_NUMBER="${DSPACE_VERSION_NUMBER:-7_x}" # it's important to use the 7_x maintenance tag, so we get bug fixes and security updates
export DSPACE_VER="dspace-${DSPACE_VERSION_NUMBER}"
export DSPACE_WORKSPACE="${HOME}/dspace-workspace"
export BACKEND_SRC="${DSPACE_WORKSPACE}/dspace/docker-compose-cdl.yml"
export FRONTEND_SRC="${DSPACE_WORKSPACE}/dspace-angular/docker/docker-compose-cdl-dist.yml"
export REGION="${REGION:-us-west-2}"
export ACCT="${ACCT:-866216109762}"
export BACKEND_IMAGE="${BACKEND_IMAGE:-dspace/dspace}"
export FRONTEND_IMAGE="${FRONTEND_IMAGE:-cdl/dspace-angular}"
export BACKEND_IMAGE_TAG="${DSPACE_VER:-latest}"
export FRONTEND_IMAGE_TAG="cdl-latest-dist"
export OTHER_IMAGES="${OTHER_IMAGES:-dspace/dspace-solr:${BACKEND_IMAGE_TAG:-latest} dspace/dspace-cli:${BACKEND_IMAGE_TAG:-latest}}" # note that these images will be pushed to ECR, but not built, handy for copying images from DockerHub, etc.

# Parse command-line options
usage() {
  echo "Usage: $0 [-h] [--skip IMAGES]"
  echo "Build and push DSpace Docker images to AWS ECR"
  echo ""
  echo "Options:"
  echo "  -h, --help           Show this help message and exit"
  echo "  --skip IMAGES        Comma-delimited list of images to skip, valid values are 'backend', 'frontend', 'other'"
  echo ""
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --skip)
      if [[ -z "$2" || "$2" == -* ]]; then
        echo "Error: Missing argument for --skip option" >&2
        exit 1
      fi
      SKIP_IMAGES="$2"
      shift 2
      ;;
    *)
      echo "Error: Invalid option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

# Build list of images to push
IMAGES=()
if [[ ! " ${SKIP_IMAGES[@]} " =~ "backend" ]]; then
  IMAGES+=("$BACKEND_IMAGE:$BACKEND_IMAGE_TAG")
fi
if [[ ! " ${SKIP_IMAGES[@]} " =~ "frontend" ]]; then
  IMAGES+=("$FRONTEND_IMAGE:$FRONTEND_IMAGE_TAG")
fi
if [[ ! " ${SKIP_IMAGES[@]} " =~ "other" ]]; then
  IMAGES+=("${OTHER_IMAGES[@]}")
fi

echo "==== Pulling Docker images to our local repository ===="
for image in $OTHER_IMAGES; do
    docker pull --platform linux/amd64 ${image} # note that image strings should include tags, otherwise you're getting "latest", which may not be what you want
done

# save this for later, skip building for now
# echo "==== Building Docker images for DSpace using Docker Compose ===="
# docker-compose -f $BACKEND_SRC -f $FRONTEND_SRC build --progress tty




echo "==== Tagging Docker images so they can be pushed ===="
#docker tag image:tag $ACCT.dkr.ecr.$REGION.amazonaws.com/image:tag
for image in $IMAGES; do
	docker tag ${image} $ACCT.dkr.ecr.$REGION.amazonaws.com/${image}
done

# removing Trivy for now, it's way too sensitive and slow, we'll use AWS ECR image scanning instead
# echo "===== Scanning for vulnerabilities ====="
# for image in $IMAGES; do
# 	trivy --severity critical,high image --exit-code 1 --quiet --scanners vuln --ignore-unfixed ${image}
# done

echo "==== Logging in to AWS ECR ===="
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCT.dkr.ecr.$REGION.amazonaws.com

echo "==== Pushing images to ECR, starting image scan ===="
for image in $IMAGES; do
	docker push $ACCT.dkr.ecr.$REGION.amazonaws.com/${image}
	set +e #disable exit on error, because we don't care if the next request for an image scan fails
	aws ecr start-image-scan --repository-name $(echo $image | cut -d':' -f1) --image-id imageTag=$(echo $image | cut -d':' -f2)
	set -e #re-enable exit on error
done

echo "==== Build complete ===="
echo "To validate this build, run the following commands after about ten minutes (the image scan takes a while):"
echo "More info here: https://docs.aws.amazon.com/cli/latest/reference/ecr/describe-image-scan-findings.html"
echo
for image in $IMAGES; do
	echo "aws ecr describe-image-scan-findings --repository-name $(echo $image | cut -d':' -f1) --image-id imageTag=$(echo $image | cut -d':' -f2)" || true # AWS doesn't like re-running this command, so we'll just ignore the error
done
echo
echo "========================"
exit 0
