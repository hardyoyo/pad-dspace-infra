#!/bin/bash

set -euo pipefail

export AWS_PROFILE=cdl-main
export FUNC=web-matomo-prd

TASK_ARN=$(aws ecs list-tasks --cluster ${FUNC}-cluster --query "taskArns" --output text)
echo "task: $TASK_ARN"

aws ecs execute-command --cluster ${FUNC}-cluster --task $TASK_ARN \
    --container ${FUNC}-TaskDef --command "/bin/bash" --interactive