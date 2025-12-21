# Initial Setup Guide

This guide covers the one-time configuration steps required to prepare your GCP account and GitHub repository for the Chuck Norris Jokes application.

## 1. GCP Project Prerequisites

Before starting, ensure you have:
1.  A **GCP Project** with billing enabled.
2.  The **`gcloud` CLI** installed and authenticated (`gcloud auth login`).
3.  A **GCS Bucket** for Terraform state.
4.  An **Artifact Registry** repository (Docker format) named `chuck-registry`.

### Infrastructure Foundation

Run these commands to set up the basic resources:

```bash
# Set your project ID
export PROJECT_ID="your-project-id"
export REGION="us-central1"

# Create State Bucket (enable versioning for safety)
gsutil mb -p $PROJECT_ID -l ${REGION} gs://${PROJECT_ID}-tfstate
gsutil versioning set on gs://${PROJECT_ID}-tfstate

# Create Artifact Registry
gcloud artifacts repositories create chuck-registry \
    --repository-format=docker \
    --location=${REGION} \
    --description="Docker repository for Chuck Norris app"
```

## 2. Service Account Setup

Create a dedicated service account for CI/CD operations with least-privilege access.

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
| Role | Purpose |
|------|---------|
| `roles/run.admin` | Manage Cloud Run services |
| `roles/artifactregistry.admin` | Push images to Artifact Registry |
| `roles/compute.admin` | Manage Load Balancer and Network groups |
| `roles/iam.serviceAccountUser` | Act as the service account |
| `roles/storage.admin` | Manage Terraform state and Function source in GCS |
| `roles/iam.serviceAccountTokenCreator` | Required for Workload Identity Federation |
| `roles/serviceusage.serviceUsageAdmin` | Enable APIs for the project |
| `roles/iam.serviceAccountAdmin` | Create and manage Service Accounts |
| `roles/cloudfunctions.admin` | Manage FinOps Cloud Functions |
| `roles/cloudscheduler.admin` | Manage FinOps Start/Stop schedules |
| `roles/pubsub.admin` | Manage FinOps trigger topics |
| `roles/cloudbuild.builds.editor` | Build Cloud Functions Gen2 source |

## 3. Workload Identity Federation (WIF)

Set up keyless authentication from GitHub Actions to GCP.

### Recommended: Use Helper Script
We provide a script to handle the complex OIDC configuration automatically:

```bash
chmod +x scripts/setup-wif.sh
./scripts/setup-wif.sh
```

### Manual Setup (Optional)
If you prefer manual configuration, refer to the OIDC commands in the [setup-wif.sh](file:///Users/malovany/Library/Mobile%20Documents/com~apple~CloudDocs/Documents/AI/chuck-infra/scripts/setup-wif.sh) script, ensuring the `attribute-condition` matches your GitHub organization/repository.

## 4. GitHub Secrets Configuration

Add the following secrets to your GitHub repository (**Settings > Secrets and variables > Actions**):

| Secret | Value |
|--------|-------|
| `GCP_PROJECT_ID` | Your GCP project ID |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | The full resource name of the WIF provider |
| `GCP_SERVICE_ACCOUNT` | `chuck-deployer@${PROJECT_ID}.iam.gserviceaccount.com` |
| `TF_STATE_BUCKET` | `${PROJECT_ID}-tfstate` (Just the name, no `gs://` prefix) |
| `PAT_TOKEN` | A GitHub Personal Access Token with `repo` scope (for GitOps commits) |

---

**Next Step**: Once setup is complete, proceed to the [Deployment Guide](deployment-guide.md) to launch the application.
