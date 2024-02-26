#!/bin/bash
set -eou pipefail

# Set AWS profile and function name
export AWS_PROFILE=${AWS_PROFILE:-cdl-pad-prd}
export FUNC=pub-dspace
export CDL_ENVIRONMENT=${CDL_ENVIRONMENT:-dev}
export ENVIRONMENT="${FUNC}-${CDL_ENVIRONMENT}"

# Specify the S3 bucket
S3_BUCKET="$FUNC-config"
S3_FOLDER="env"
DOTENV_DIR="dotenv"

# Check if dotenv-linter is installed
if ! command -v dotenv-linter &> /dev/null
then
    echo "Error: dotenv-linter is not installed. Please install it from https://github.com/dotenv-linter/dotenv-linter and try again."
    exit  1
fi

# Recursively check all dotfiles in the project, quietly
echo "Validating all dotenv files..."
dotenv-linter -r

echo "Pushing all dotenv files to S3..."
# Iterate over each .env file in the dotenv directory
for file in "$DOTENV_DIR"/*.env; do
  # Check if the file exists (to avoid errors if no files match the pattern)
  if [ -f "$file" ]; then
    # Use the AWS CLI to copy the file to the S3 bucket
    aws s3 cp "$file" "s3://$S3_BUCKET/$S3_FOLDER/"
  else
    echo "Error: $file not found in $DOTENV_DIR"
    exit  1
  fi
done

echo "✅ All .env files have been pushed to S3."

exit  0