#!/bin/bash

# TODO: add a paramter for which service/task to shell into (frontend, backend, solr, cli)
# TODO: figure out how to query the TASK ARN using the name of the task we pass in here

set -euo pipefail

export AWS_PROFILE=cdl-pad-dev
export FUNC=pub-dspace-dev

# FIXME: the next line assumes we only have one running task, that's not correct
TASK_ARN=$(aws ecs list-tasks --cluster ${FUNC}-cluster --query "taskArns" --output text)
echo "task: $TASK_ARN"

aws ecs execute-command --cluster ${FUNC}-cluster --task $TASK_ARN \
    --container ${FUNC}-TaskDef --command "/bin/bash" --interactive
