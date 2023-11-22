#!/bin/bash

set -euo pipefail

# Uncomment for debug
# set -x

export AWS_PROFILE=${AWS_PROFILE:-cdl-pad-dev}
export FUNC=${FUNC:-pub-dspace-dev}

show_usage() {
    echo "Usage: $0 <service_component> e.g. backend, frontend, solr"
    echo "Example: $0 backend"
    echo
    exit 1
}

get_service_message() {
    AWS_PROFILE=$1 aws ecs describe-services \
        --cluster $2 --service $3 \
        --query services[0].events[0].message
}

get_service_info() {
    AWS_PROFILE=$1 aws ecs describe-services \
        --cluster $2 --service $3 \
        --query 'services[0].[deployments, runningCount, desiredCount]' \
        --output json | \
        jq -r '.[0] | if type == "array" then length else 0 end'
}

# Check if '-h' or '--help' is provided as an argument
if [[ "$1" == '-h' || "$1" == '--help' ]]; then
    show_usage
fi

# Check if no service name is provided or too many parameters are given
if [ $# -ne 1 ]; then
    show_usage
fi

# Get the service short name from the command line
SERVICE_COMPONENT=$1

# Build the SERVICE name
SERVICE="${FUNC}-${SERVICE_COMPONENT}-service"

# Build the CLUSTER name
CLUSTER="${FUNC}-cluster"

last_msg=$(get_service_message $AWS_PROFILE $CLUSTER $SERVICE)

echo "Telling $SERVICE to update..."
if ! AWS_PROFILE=$AWS_PROFILE aws ecs update-service --cluster $CLUSTER --service $SERVICE --force-new-deployment > /dev/null; then
    echo "Error: Failed to update $SERVICE."
    exit 1
fi

echo "Waiting for $SERVICE to stabilize."
while true; do
    cur_msg=$(get_service_message $AWS_PROFILE $CLUSTER $SERVICE)

    if [ "$last_msg" != "$cur_msg" ]; then
        echo "    ${cur_msg//\"/}"
        last_msg="$cur_msg"
    fi

    if ! read -r ndep running desired < <(get_service_info $AWS_PROFILE $CLUSTER $SERVICE); then
        echo "Error: Failed to retrieve service information for $SERVICE."
        exit 1
    fi

    if [ "$ndep" == 1 ] && [ "$running" == "$desired" ]; then
        timestamp=$(date +"%Y-%m-%d %I:%M:%S %p")
        echo "✅ Success: $SERVICE is stable. Timestamp: $timestamp"
        exit 0
    fi

    sleep 5
done

