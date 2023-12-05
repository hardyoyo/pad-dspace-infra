#!/bin/bash

usage() {
    echo "Usage: $0 [-t <task-definition-name> | -l]"
    echo "Options:"
    echo "  -t <task-definition-name>: Specify the task definition name."
    echo "  -l: List all available task definitions."
    echo "  -h: Display this help message."
    exit 1
}

list_task_definitions() {
    aws ecs list-task-definitions | yq -P
}

while getopts ":t:lh" opt; do
    case $opt in
        t)
            task_definition_name="$OPTARG"
            ;;
        l)
            list_task_definitions
            exit 0
            ;;
        h)
            usage
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            usage
            ;;
    esac
done

if [ -z "$task_definition_name" ]; then
    echo "Error: Task definition name is required."
    usage
fi

template_folder="templates"

# Describe the task definition using AWS CLI
task_definition_json=$(aws ecs describe-task-definition --task-definition "$task_definition_name")

# Use jq to extract and format relevant information
family=$(echo "$task_definition_json" | jq -r '.taskDefinition.family')
container_definitions=$(echo "$task_definition_json" | jq -r '.taskDefinition.containerDefinitions | tojson' | yq -P)

# Jinja template in YAML format
template="${template_folder}/${task_definition_name}-taskdef.yaml.j2"
mkdir -p "$template_folder"  # Create the 'templates' folder if it doesn't exist
cat <<EOF > "$template"
---
family: $family
containerDefinitions: $container_definitions
EOF

echo "Jinja template saved to $template in the $template_folder folder."

exit 0
