#!/bin/bash
# shellcheck disable=SC2199

set -euo pipefail

# uncomment for debug
# set -x

function should_skip_image() {
  local image_name="$1"
  local skip_images=("${SKIP_IMAGES//,/ }")
  for skip_image in "${skip_images[@]}"; do
    if [[ "$image_name" == "$skip_image" ]]; then
      # echo "DEBUG: should_skip_image: Skipping $image_name"
      return 0 # zero = true in Bash
    fi
  done
  # echo "DEBUG: should_skip_image: Not skipping $image_name"
  return 1 # one = false in Bash
}




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
export FRONTEND_PATH="${DSPACE_WORKSPACE}/dspace-angular"
export BACKEND_PATH="${DSPACE_WORKSPACE}/dspace"
# TODO: change these to the Dockerfile we'll use for each with buildx, not Docker-Compose
export BACKEND_SRC="${BACKEND_PATH}/docker-compose-cdl.yml"
export FRONTEND_SRC="./Dockerfile.cdl-dist"
export REGION="${REGION:-us-west-2}"
export ACCT="${ACCT:-866216109762}"
export BACKEND_IMAGE="${BACKEND_IMAGE:-dspace/dspace}"
export FRONTEND_IMAGE="${FRONTEND_IMAGE:-cdl/dspace-angular}"
export BACKEND_IMAGE_TAG="${DSPACE_VER:-latest}"
export FRONTEND_IMAGE_TAG="cdl-latest-dist"
export OTHER_IMAGES="${OTHER_IMAGES:-dspace/dspace-solr:${BACKEND_IMAGE_TAG:-latest} dspace/dspace-cli:${BACKEND_IMAGE_TAG:-latest}}" # note that these images will be pushed to ECR, but not built, handy for copying images from DockerHub, etc.
export FRONTEND_URI="${ACCT}.dkr.ecr.${REGION}.amazonaws.com/${FRONTEND_IMAGE}"
export BACKEND_URI="${ACCT}.dkr.ecr.${REGION}.amazonaws.com/${BACKEND_IMAGE}"

# Flag to enable Trivy vulnerability scanning
USE_TRIVY=true
VERBOSE_TRIVY=false

# Parse command-line options
usage() {
  echo "Usage: $0 [-h] [--skip IMAGES]"
  echo "Build and push DSpace Docker images to AWS ECR"
  echo ""
  echo "Options:"
  echo "  -h, --help           Show this help message and exit"
  echo "  --skip IMAGES        Comma-delimited list of images to skip, valid values are 'backend', 'frontend', 'other'"
  echo "  --no-trivy           Don't use Trivy to scan images for vulnerabilities before pushing them (trivy on by default)"
  echo "  --verbose            Print verbose Trivy scan results (default: false)"
  echo "  --debug              Print debug information (off by default)"
  echo ""
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --no-trivy)
      USE_TRIVY=false
      shift
      ;;
    --debug)
      set -x
      shift
      ;;
    --verbose)
      VERBOSE_TRIVY=true
      shift
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

echo "==== Pulling Docker images to our local registry ===="
for image in $OTHER_IMAGES; do
    docker pull -q --platform linux/amd64 "${image}" # note that image strings should include tags, otherwise you're getting "latest", which may not be what you want
done

# echo "==== Logging in to AWS ECR ===="
# aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ACCT.dkr.ecr.$REGION.amazonaws.com"

# Build Docker images for DSpace using Docker Compose
echo "==== Building Docker images for DSpace using Docker Buildx, for local registry ===="

# Build backend image if not skipped
# echo "DEBUG: IMAGES=${IMAGES[@]}"
# echo "DEBUG: SKIP_IMAGES=${SKIP_IMAGES[@]}"
# echo "DEBUG: should_skip_image backend: $(should_skip_image 'backend')"

# BACKEND BUILD ###############################################################

# Build backend image if not skipped
if should_skip_image "backend"; then
  echo "Skipping backend image build"
else
  #Use buildx instead of docker-compose to build and push a multi-platform image
  # docker-compose -f $BACKEND_SRC build --progress tty dspace
  # TODO: develop and test a Dockerfile to use for buildx, which assumes that mvn has been run locally
  #docker buildx create --use
  #cd "$BACKEND_PATH" && buildx create --use && docker buildx build --platform linux/arm64,linux/amd64 -t "$BACKEND_URI" dspace --push
  echo "eventually the backend will be built, but not right now..."
fi

# FRONTEND BUILD ##############################################################

# Build frontend image if not skipped
if should_skip_image "frontend"; then
  echo "Skipping frontend image build"
else
  #Use buildx to build and push an amd64 image (can be multi-platform, but amd64 is necessary for Fargate)
  # docker-compose -f $FRONTEND_SRC build --progress tty dspace-angular
  # echo "FRONTEND_IMAGE = $FRONTEND_IMAGE"
  # echo "FRONTEND_URI = $FRONTEND_URI"
  cd "$FRONTEND_PATH" && docker buildx create --use && docker buildx build --platform linux/amd64 -t "$FRONTEND_IMAGE:$FRONTEND_IMAGE_TAG" -f "$FRONTEND_SRC" --load .
  # docker buildx build -t dspace-angular-cdl-test:dspace-7_x --platform linux/amd64 -f ./Dockerfile.cdl-dist .
fi


echo "==== Tagging Docker images so they can be pushed ===="
for image in "${IMAGES[@]}"; do
	docker tag "${image}" "$ACCT.dkr.ecr.$REGION.amazonaws.com/${image}"
done

if $USE_TRIVY; then
echo "===== Scanning for vulnerabilities with Trivy ====="
  for image in "${IMAGES[@]}"; do
    image_id=$(docker inspect -f '{{.Id}}' "${image}")
    if [[ "${VERBOSE_TRIVY}" == "false" ]]; then
      echo -e "\n${image}: "
      # shellcheck disable=SC2016
      trivy --quiet image \
    --format template \
    --template '{{- $critical := 0 }}{{- $high := 0 }}{{- range . }}{{- range .Vulnerabilities }}{{- if  eq .Severity "CRITICAL" }}{{- $critical = add $critical 1 }}{{- end }}{{- if  eq .Severity "HIGH" }}{{- $high = add $high 1 }}{{- end }}{{- end }}{{- end }}Critical: {{ $critical }}, High: {{ $high }}' \
    --severity critical,high \
    --exit-code 0 \
    --scanners vuln \
    --ignore-unfixed \
      "${image_id}"
      echo -e "\n\n"
    else
      echo -e "\n${image}: "
      trivy --quiet image \
        --format json \
        --severity critical,high \
        --exit-code 0 \
        --scanners vuln \
        --ignore-unfixed \
        "${image_id}" \
        | yq -P
        echo -e "\n\n"
    fi
  done
else
  echo "===== Skipping vulnerability scanning ====="
fi


echo "==== Logging in to AWS ECR ===="
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ACCT.dkr.ecr.$REGION.amazonaws.com"

echo "==== Pushing images to ECR ===="
for image in "${IMAGES[@]}"; do
	docker push "$ACCT.dkr.ecr.$REGION.amazonaws.com/${image}"
done

echo "==== Build complete ===="
echo "To validate this build, run the following commands after about ten minutes (the image scan takes a while):"
echo "More info here: https://docs.aws.amazon.com/cli/latest/reference/ecr/describe-image-scan-findings.html"
echo
for image in "${IMAGES[@]}"; do
	echo "aws ecr describe-image-scan-findings --repository-name $(echo "$image" | cut -d':' -f1) --image-id imageTag=$(echo "$image" | cut -d':' -f2)"
done
echo
echo "========================"
exit 0
