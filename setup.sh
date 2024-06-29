#!/bin/bash
set -euo pipefail

# See https://cloud.google.com/blog/products/identity-security/enabling-keyless-authentication-from-github-actions

REMOTE_URL=$(git remote get-url origin)
if [[ $REMOTE_URL == git@* ]]; then
  GITHUB_REPOSITORY=$(echo "$REMOTE_URL" | sed -E 's/^git@[^:]+:(.+)\.git$/\1/')
elif [[ $REMOTE_URL == https://* ]]; then
  GITHUB_REPOSITORY=$(echo "$REMOTE_URL" | sed -E 's/^https:\/\/[^/]+\/(.+)\.git$/\1/')
else
  echo "Unknown remote URL format: $REMOTE_URL"
  exit 1
fi

PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUMBER=$(gcloud projects list --filter="project_id=$PROJECT_ID" --format='value(project_number)')

gcloud iam workload-identity-pools create "my-pool" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --display-name="Demo pool"

gcloud iam workload-identity-pools providers create-oidc "my-provider" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="my-pool" \
  --display-name="Demo provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.aud=assertion.aud" \
  --issuer-uri="https://token.actions.githubusercontent.com"

gcloud iam service-accounts add-iam-policy-binding "terraform@${PROJECT_ID}.iam.gserviceaccount.com" \
  --project="${PROJECT_ID}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principal://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/my-pool/subject/repo:${GITHUB_REPOSITORY}:pull_request"
