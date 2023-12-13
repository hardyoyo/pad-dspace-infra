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

# Build cluster name
CLUSTER_NAME="${FUNC}-cluster"

# Build the service family based on the provided function and service name
SERVICE_FAMILY="${FUNC}-${SERVICE_NAME}"

# Build service
SERVICE="$SERVICE_FAMILY-service"

CURRENT_COUNT=$(aws ecs describe-services --cluster "$CLUSTER_NAME" --services "$SERVICE" --query 'services[0].desiredCount' --output text)

# Toggle the desired task count
if [ "$CURRENT_COUNT" -eq 0 ]; then
        NEW_COUNT=1
    else
            NEW_COUNT=0
fi

# Execute command to toggle the number of tasks for the specified service
echo
echo " 🔀  Toggling ${SERVICE}, setting desiredCount of tasks to ${NEW_COUNT} (was ${CURRENT_COUNT})."
echo
result=$(aws ecs update-service --cluster "$CLUSTER_NAME" --service "$SERVICE" --desired-count "$NEW_COUNT")

echo "Waiting for $SERVICE to stabilize."
while true; do
   CURRENT_COUNT=$(aws ecs describe-services --cluster "$CLUSTER_NAME" --services "$SERVICE" --query 'services[0].desiredCount' --output text) 

    if [ "$CURRENT_COUNT" == "$NEW_COUNT" ]; then
		echo "✅ Success: $SERVICE is stable."
        echo "(task count: ${CURRENT_COUNT} of ${NEW_COUNT} desired)"
        exit 0
    fi
    sleep 5
done

exit 0
