#!/bin/bash
set -eou pipefail

# Set AWS profile and function name
export AWS_PROFILE=${AWS_PROFILE:-cdl-pad-dev}
export FUNC=pub-dspace-dev

# Specify the S3 bucket
S3_BUCKET="$FUNC-config"
S3_FOLDER="env"
DOTENV_FILES="config/env/*.env"


# Check if dotenv-linter is installed
if ! command -v dotenv-linter &> /dev/null
then
    echo "Error: dotenv-linter is not installed. Please install it from https://github.com/dotenv-linter/dotenv-linter and try again."
    exit 1
fi

# Recursively check all dotfiles in the project, quietly
echo "Validating all dotenv files..."
dotenv-linter -rq

echo "Pushing all dotenv files to S3..."
# Copy dotenv file to S3 bucket
aws s3 cp $DOTENV_FILES "s3://$S3_BUCKET/$S3_FOLDER/"

exit 0
