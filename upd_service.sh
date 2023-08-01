#!/bin/bash

set -euo pipefail

LAST_MSG=$(AWS_PROFILE=cdl-main aws ecs describe-services \
              --cluster web-matomo-prd-cluster --service web-matomo-prd-Service \
              --query services[0].events[0].message)

echo "Telling service to update."
AWS_PROFILE=cdl-main aws ecs update-service --cluster web-matomo-prd-cluster --service web-matomo-prd-Service --force-new-deployment > /dev/null

echo "Waiting for service to stabilize."
while true; do
  CUR_MSG=$(AWS_PROFILE=cdl-main aws ecs describe-services \
            --cluster web-matomo-prd-cluster --service web-matomo-prd-Service \
            --query services[0].events[0].message)
  if [ "$LAST_MSG" != "$CUR_MSG" ]; then
    echo -n "    "
    echo "$CUR_MSG" | sed 's/"//g'
    LAST_MSG="$CUR_MSG"
  fi

  ndep=$(AWS_PROFILE=cdl-main aws ecs describe-services \
            --cluster web-matomo-prd-cluster --service web-matomo-prd-Service \
            --query 'length(services[0].deployments)')
  read -r running desired < <(AWS_PROFILE=cdl-main aws ecs describe-services \
            --cluster web-matomo-prd-cluster --service web-matomo-prd-Service \
            --query 'services[0].[runningCount,desiredCount]' --output text)
  if [ "$ndep" == 1 ] && [ "$running" == "$desired" ]; then
    echo "Looks stable."
    break
  fi

  sleep 5
done

echo "Update complete."
