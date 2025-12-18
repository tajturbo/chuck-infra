# Deployment Guide

Complete guide for deploying the Chuck Norris Jokes application to GCP.

## Prerequisites

- GCP project with billing enabled
- `gcloud` CLI installed
### 2. Infrastructure Prerequisites
You will need:
1.  A **GCP Project** with billing enabled.
2.  A **GCS Bucket** for Terraform state.
3.  An **Artifact Registry** repository (Docker format).

Run these commands to set them up:
```bash
# Set your project ID
export PROJECT_ID="your-project-id"
export REGION="us-central1"

# Create State Bucket
gcloud storage buckets create gs://${PROJECT_ID}-tfstate --location=${REGION}

# Create Artifact Registry (Manual Step)
gcloud artifacts repositories create chuck-registry \
    --repository-format=docker \
    --location=${REGION} \
    --description="Docker repository for Chuck Norris app"
```


### Create Terraform State Bucket

```bash
gsutil mb -p $PROJECT_ID -l us-central1 gs://${PROJECT_ID}-tfstate
gsutil versioning set on gs://${PROJECT_ID}-tfstate
```

### Create Service Account

```bash
# Create service account
gcloud iam service-accounts create chuck-deployer \
  --display-name="Chuck Norris App Deployer"

SA_EMAIL="chuck-deployer@${PROJECT_ID}.iam.gserviceaccount.com"

# Grant required roles
for ROLE in \
  roles/run.admin \
  roles/artifactregistry.admin \
  roles/compute.admin \
  roles/iam.serviceAccountUser \
  roles/iam.serviceAccountTokenCreator \
  roles/storage.admin
do
  gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="${ROLE}"
done
```

### Required Permissions Summary
The Service Account needs the following roles:
| Role | Purpose |
|------|---------|
| `roles/run.admin` | Manage Cloud Run services |
| `roles/artifactregistry.admin` | Push images to Artifact Registry |
| `roles/compute.admin` | Manage Load Balancer and Network groups |
| `roles/iam.serviceAccountUser` | Act as the service account |
| `roles/storage.admin` | Manage Terraform state in GCS |
| `roles/iam.serviceAccountTokenCreator` | Required for WIF token exchange |


## 2. Workload Identity Federation

Set up keyless authentication from GitHub Actions.

### Recommended: Use Helper Script
We have provided a helper script that handles the setup automatically:

```bash
./scripts/setup-wif.sh
```

### Manual Setup
If you prefer to run commands manually, use these updated commands which include the required repository owner constraint:

```bash
# Create Workload Identity Pool
gcloud iam workload-identity-pools create "github-pool" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --display-name="GitHub Actions Pool"

# Create Provider (with repo owner constraint to pass validation)
gcloud iam workload-identity-pools providers create-oidc "github-provider" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="github-pool" \
  --display-name="GitHub Provider" \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
  --attribute-condition="assertion.repository_owner=='fromthehell666'"

# Update Attribute Mapping (optional cleanup)
gcloud iam workload-identity-pools providers update-oidc "github-provider" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="github-pool" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository"

# Get the Workload Identity Provider resource name
export WIP=$(gcloud iam workload-identity-pools providers describe github-provider \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="github-pool" \
  --format="value(name)")

echo "Workload Identity Provider: $WIP"

# Allow your repo to impersonate the service account
export REPO="fromthehell666/chuck-infra"

gcloud iam service-accounts add-iam-policy-binding "${SA_EMAIL}" \
  --project="${PROJECT_ID}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/${WIP}/attribute.repository/${REPO}"
```

## 3. GitHub Secrets Configuration

Add these secrets to your GitHub repository:

| Secret | Value |
|--------|-------|
| `GCP_PROJECT_ID` | Your GCP project ID |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | The `$WIP` value from step 2 |
| `GCP_SERVICE_ACCOUNT` | `chuck-deployer@${PROJECT_ID}.iam.gserviceaccount.com` |
| `TF_STATE_BUCKET` | `${PROJECT_ID}-tfstate` (Just the name, **NO** `gs://` prefix) |

## 4. Initial Deployment

### Step 1: Build and Push First Image

Push code to `main` branch or run `docker-build` workflow.

### Step 2: Provision Infrastructure

Run `infra-provision` workflow:
- Environment: `dev`
- Action: `plan` (review)
- Action: `apply` (create resources)

Repeat for `stg` and `prod` as needed.

### Step 3: Deploy Application

Run `app-deploy` workflow or let it auto-trigger after build.

## 5. Zero-Downtime Deployment Process

```
┌──────────────────────────────────────────────────────────────┐
│  1. Build new Docker image                                   │
│     ↓                                                        │
│  2. Push to Artifact Registry                                │
│     ↓                                                        │
│  3. Deploy new Cloud Run revision (0% traffic)               │
│     ↓                                                        │
│  4. Run integration tests on canary                          │
│     ↓                                                        │
│  5. Shift traffic to 50%                                     │
│     ↓                                                        │
│  6. Monitor health                                           │
│     ↓                                                        │
│  7. Shift traffic to 100%                                    │
│     ↓                                                        │
│  ✓ Deployment complete                                       │
│                                                              │
│  ✗ On failure: Auto-rollback to previous revision           │
└──────────────────────────────────────────────────────────────┘
```

## 6. Manual Rollback

If you need to manually rollback:

```bash
ENV="dev"  # or stg, prod
REGION="us-central1"

# List revisions
gcloud run revisions list \
  --service=chuck-${ENV}-primary \
  --region=${REGION}

# Rollback to specific revision
gcloud run services update-traffic chuck-${ENV}-primary \
  --region=${REGION} \
  --to-revisions=REVISION_NAME=100
```

## 7. Monitoring

### Cloud Run Metrics
```bash
gcloud run services describe chuck-dev-primary \
  --region=us-central1 \
  --format='value(status.url)'
```

### Logs
```bash
gcloud run services logs read chuck-dev-primary --region=us-central1
```

## 8. Cleanup

To destroy an environment:

```bash
# Run infra-provision workflow with action: destroy
# Or manually:
cd infra
terraform init -backend-config="bucket=${PROJECT_ID}-tfstate" -backend-config="prefix=chuck-dev"
terraform destroy -var="project_id=${PROJECT_ID}" -var="environment=dev"
```

## Troubleshooting

### "Permission denied" errors
- Verify service account has all required roles
- Check Workload Identity Federation is correctly configured

### "Image not found" errors
- Ensure registry exists: run `infra-provision` first
- Check image tag matches the deployed revision

### Terraform state lock
```bash
terraform force-unlock LOCK_ID
```

### Local Debugging (Impersonation)
If you see `PERMISSION_DENIED` when running `gcloud ... --impersonate-service-account`, you need to grant your user account the ability to create tokens for the Service Account:

```bash
gcloud iam service-accounts add-iam-policy-binding "chuck-deployer@${PROJECT_ID}.iam.gserviceaccount.com" \
  --project="${PROJECT_ID}" \
  --member="user:your-email@gmail.com" \
  --role="roles/iam.serviceAccountTokenCreator"
```
*Note: This permission can take 1-2 minutes to propagate.*
