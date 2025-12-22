#!/bin/bash
set -e

# Configuration
POOL_NAME="github-pool"
PROVIDER_NAME="github-provider"
PROJECT_ID=$(gcloud config get-value project)
REPO_OWNER="tajturbo"

echo "Setting up Workload Identity Federation for project: $PROJECT_ID"

# 1. Create Workload Identity Pool
echo "Creating Workload Identity Pool..."
if ! gcloud iam workload-identity-pools describe "$POOL_NAME" --location="global" >/dev/null 2>&1; then
    gcloud iam workload-identity-pools create "$POOL_NAME" \
        --project="$PROJECT_ID" \
        --location="global" \
        --display-name="GitHub Actions Pool"
else
    echo "Pool $POOL_NAME already exists."
fi

# 2. Create Provider (Basic - No Mappings to avoid validation bugs)
echo "Creating OIDC Provider (step 1/2)..."
if ! gcloud iam workload-identity-pools providers describe "$PROVIDER_NAME" --workload-identity-pool="$POOL_NAME" --location="global" >/dev/null 2>&1; then
    gcloud iam workload-identity-pools providers create-oidc "$PROVIDER_NAME" \
    --project="$PROJECT_ID" \
    --location="global" \
    --workload-identity-pool="$POOL_NAME" \
    --display-name="GitHub Provider" \
    --issuer-uri="https://token.actions.githubusercontent.com" \
    --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
    --attribute-condition="assertion.repository_owner==${REPO_OWNER}"
else
    echo "Provider $PROVIDER_NAME already exists."
fi

# 3. Configure/Update Attribute Mapping
echo "Configuring Attribute Mappings (step 2/2)..."
gcloud iam workload-identity-pools providers update-oidc "$PROVIDER_NAME" \
    --project="$PROJECT_ID" \
    --location="global" \
    --workload-identity-pool="$POOL_NAME" \
    --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository"

# 4. Bind Service Account to Workload Identity Pool
echo "Binding Service Account to Pool (step 3/3)..."
SERVICE_ACCOUNT="chuck-deployer@${PROJECT_ID}.iam.gserviceaccount.com"
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)")
POOL_ID="projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_NAME}"
MEMBER="principalSet://iam.googleapis.com/${POOL_ID}/attribute.repository/${REPO_OWNER}/chuck-infra"

gcloud iam service-accounts add-iam-policy-binding "$SERVICE_ACCOUNT" \
    --project="$PROJECT_ID" \
    --role="roles/iam.workloadIdentityUser" \
    --member="$MEMBER"

# 4. Grant Project-Level Permissions to Service Account
echo "Granting roles to Service Account (step 4/5)..."
for ROLE in \
  roles/run.admin \
  roles/artifactregistry.admin \
  roles/compute.admin \
  roles/iam.serviceAccountUser \
  roles/storage.admin \
  roles/serviceusage.serviceUsageAdmin \
  roles/iam.serviceAccountAdmin \
  roles/resourcemanager.projectIamAdmin
do
  echo "Adding role: $ROLE"
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${SERVICE_ACCOUNT}" \
    --role="${ROLE}" \
    --quiet >/dev/null
done
# 5. Output Configuration for GitHub Secrets
echo "==================================================="
echo "Setup Complete!"
echo "Put this value in your GitHub Secret GCP_WORKLOAD_IDENTITY_PROVIDER:"
gcloud iam workload-identity-pools providers describe "$PROVIDER_NAME" \
    --project="$PROJECT_ID" \
    --location="global" \
    --workload-identity-pool="$POOL_NAME" \
    --format="value(name)"
echo "==================================================="
