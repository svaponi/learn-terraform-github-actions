#!/bin/bash
set -euo pipefail

remote_url=$(git remote get-url origin)
if [[ $remote_url == git@* ]]; then
  GITHUB_REPOSITORY=$(echo "$remote_url" | sed -E 's/^git@[^:]+:(.+)\.git$/\1/')
elif [[ $remote_url == https://* ]]; then
  GITHUB_REPOSITORY=$(echo "$remote_url" | sed -E 's/^https:\/\/[^/]+\/(.+)\.git$/\1/')
else
  echo "Unknown remote URL format: $remote_url"
  exit 1
fi

if [ "$(git branch --show-current)" == "main" ]; then
  ENV_NAME="production"
else
  ENV_NAME="development"
fi

GOOGLE_CLOUD_PROJECT=$(gcloud config get-value project)

rm -rf .terraform/terraform.tfstate
terraform init -backend-config="bucket=${GOOGLE_CLOUD_PROJECT}-terraformstate" -backend-config="prefix=${GITHUB_REPOSITORY#*/}-${ENV_NAME}"
terraform plan -out last.tfplan
terraform apply -auto-approve last.tfplan
