#!/bin/bash
# Validate a Sceptre environment and its stacks using yamllint and sceptre
# validate

set -euo pipefail

# Uncomment for debug
# set -x

# Function to display help text
function show_help() {
    echo "Validate a Sceptre environment and its stacks using yamllint and sceptre validate."
    echo "Usage: $0 [--help] <environment_name>"
    echo ""
    echo "Options:"
    echo "  --help     Show this help text and exit."
    echo "  <environment_name> Name of the environment to validate (required)"
    echo ""
    echo "Example:"
    echo "  ./validate_sceptre_environment.sh dev"
    exit   0
}

# Display help text if no arguments were passed or if --help was requested
if [[ $# -eq   0 ]] || [[ $1 == "--help" ]]; then
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

# Check if cfn-lint is installed
if ! command -v cfn-lint &> /dev/null
then
    echo "cfn-lint could not be found. Please install it."
    exit   1
fi

# run cfn-lint on all templates
echo "Running cfn-lint on all templates..."
if cfn-lint -t templates/*.yaml; then
    echo "   ✅ No cfn-lint errors found in templates"
else
    echo "  ❌ Errors found in templates"
    FAILED=true
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
if yamllint "$ENVIRONMENT_CONFIG"; then
    echo "   ✅ No YAML syntax errors found in $ENVIRONMENT_CONFIG"
else
    echo "  ❌ YAML syntax errors found in $ENVIRONMENT_CONFIG"
    FAILED=true
fi

echo
echo "Extracting stack names from $ENVIRONMENT_CONFIG..."
# Extract stacks from the environment config file using yq
STACKS=$(yq '.stacks[]' "$ENVIRONMENT_CONFIG")

echo

# Initialize a flag to track if any checks failed
FAILED=false

# Run sceptre validate for each stack
for STACK in $STACKS
do
    echo "Validating stack $STACK..." && echo
    echo "YAMLLINT:"
    if yamllint "$STACKS_DIR/$STACK"; then
        echo "   ✅ No YAML syntax errors found in $STACKS_DIR/$STACK"
    else
        echo "  ❌ YAML syntax errors found in $STACKS_DIR/$STACK"
        FAILED=true
    fi
    echo
    echo "SCEPTRE VALIDATE:"
    if sceptre validate "stacks/$STACK"; then
        echo "   ✅ Stack $STACK validated successfully"
    else
        echo "  ❌ Errors found in stack $STACK"
        FAILED=true
    fi
done

echo

# Check if any checks failed
if [ "$FAILED" = true ]; then
    echo "❌ Some checks failed"
    exit   1
else
    echo "✅ All checks passed"
fi

echo
exit   0
