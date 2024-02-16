#!/bin/bash

# Function to display help text
function show_help() {
    echo "Usage: $0 [--help] <environment_name>"
    echo ""
    echo "Options:"
    echo "  --help     Show this help text and exit."
    echo "  <environment_name> Name of the environment to validate (required)"
    echo ""
    echo "Example:"
    echo "  ./validate_sceptre_environment.sh dev"
    exit  0
}

# Display help text if no arguments were passed or if --help was requested
if [[ $# -eq  0 ]] || [[ $1 == "--help" ]]; then
    show_help
fi

# Check if yamllint is installed
if ! command -v yamllint &> /dev/null
then
    echo "yamllint could not be found. Please install it."
    exit   1
fi

# Check if sceptre is installed
if ! command -v sceptre &> /dev/null
then
    echo "sceptre could not be found. Please install it."
    exit   1
fi

# Define the environment name and paths
ENVIRONMENT_NAME="$1"
ENVIRONMENT_CONFIG="env/$ENVIRONMENT_NAME.yaml"
STACKS_DIR="config/stacks"

# Check if the environment config file exists
if [ ! -f "$ENVIRONMENT_CONFIG" ]
then
    echo "Environment config file $ENVIRONMENT_CONFIG does not exist."
    exit   1
fi

# Validate the environment config file with yamllint
echo "Validating YAML syntax of $ENVIRONMENT_CONFIG..."
yamllint "$ENVIRONMENT_CONFIG"

echo "Extracting stack names from $ENVIRONMENT_CONFIG..."
# Extract stacks from the environment config file using yq
STACKS=$(yq '.stacks[]' "$ENVIRONMENT_CONFIG")

echo

# Run sceptre validate for each stack
for STACK in $STACKS
do
    echo "Validating stack $STACK..." && echo
    echo "YAMLLINT:"
    yamllint "$STACKS_DIR/$STACK" && echo
    echo "SCEPTRE VALIDATE:"
    sceptre validate "stacks/$STACK"

done
exit 0
