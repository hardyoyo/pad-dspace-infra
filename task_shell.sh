#!/bin/bash

# Enable strict mode
set -euo pipefail

# Uncomment for debug
# set -x

# Set AWS profile and function name
export AWS_PROFILE=cdl-pad-dev
export FUNC=pub-dspace-dev

# Function to display script usage
show_usage() {
    echo "Usage: $0 <service_component> e.g. backend, frontend, solr"
    echo "Example: $0 backend"
    echo "NOTE: you must have configured the appropriate IAM role"
    echo "and permissions for the container, and the container"
    echo "needs the execute command flag set."
    echo 
    exit 1
}

# Check if no service/task name is provided or too many parameters are given
if test "$#" -ne 1; then
    show_usage
fi

# Check if '-h' or '--help' is provided as an argument
if [[ "$1" == '-h' || "$1" == '--help' ]]; then
    show_usage
fi

# Get the service/task name from the command line
SERVICE_NAME=$1

# Build container name
CONTAINER_NAME="dspace-${1}"

# Build the service family based on the provided function and service name
SERVICE_FAMILY="${FUNC}-${SERVICE_NAME}"

# Get the task ARN based on the specified service family
TASK_ARN=$(aws ecs list-tasks --cluster ${FUNC}-cluster --family ${SERVICE_FAMILY} --query "taskArns[0]" --output text)

if [ -z "$TASK_ARN" ]; then
    echo "No running task found for service family: $SERVICE_FAMILY"
    exit 1
fi

echo "Task: $TASK_ARN"


# known working command: aws ecs execute-command --task arn:aws:ecs:us-west-2:866216109762:task/pub-dspace-dev-cluster/db89a0a7acaa4f8f9472df53bc81b66d --cluster pub-dspace-dev-cluster --container dspace-backend --command /bin/bash --interactive

# Execute command to shell into the specified task
echo
echo " 🚀  Connecting to /bin/sh ... if bash is available on this service's container, you can type 'bash' to open a bash shell."
aws ecs execute-command --cluster ${FUNC}-cluster --task $TASK_ARN \
    --container ${CONTAINER_NAME} --command "/bin/sh" --interactive

exit 0
