# Deployment Guide

This guide covers the ongoing deployment lifecycle, operations, and maintenance of the Chuck Norris Jokes application.

> [!NOTE]
> This guide assumes you have already completed the one-time project preparation. If not, please see the **[Initial Setup Guide](initial-setup.md)** first.

## 1. Initial Deployment (Bootstrap)

Before the automated GitOps lifecycle can take over, you must perform the first-ever deployment manually to establish the infrastructure:

1.  **Build First Image**: Push code to the `main` branch or manually trigger the **`Docker Build and Push`** workflow.
2.  **Provision Infrastructure**: Manually trigger the `Infrastructure Provision` workflow:
    - Environment: `dev`
    - Action: `apply`
3.  **Verify**: Ensure the service is accessible via the Load Balancer URL provided in the workflow outputs.

## 4. Initial Deployment

### Step 1: Build and Push First Image

Push code to `main` branch or run `docker-build` workflow.

### Step 2: Provision Infrastructure

Run `infra-provision` workflow:
- Environment: `dev`
- Action: `plan` (review)
- Action: `apply` (create resources)

Repeat for `stg` and `prod` as needed.

### Step 3: Deployment lifecycle

1.  **Commit Changes**: Push your application code changes to the `/app` directory on the `main` branch.
2.  **Continuous Integration**: The **`Docker Build and Push`** workflow triggers automatically. It runs unit tests and, if successful, builds and pushes a new image to Artifact Registry.
3.  **GitOps Update**: Upon completion, the build workflow automatically updates `infra/terraform.tfvars` with the new image tag.
4.  **Automated Planning**: The update to `infra/terraform.tfvars` triggers the `Infrastructure Provision` workflow to perform a Terraform `plan` for the `dev` environment.
5.  **Manual Deployment**: A developer must manually trigger the `Infrastructure Provision` workflow with `action: apply` and `environment: dev` from the `main` branch to deploy the changes.
6.  **Automated Validation**: Once the deployment is complete, integration tests trigger automatically against the Load Balancer URL.
7.  **Release Creation**: If the `dev` deployment is successful and tests pass, merge the `release-please` PR. This creates a versioned release tag (e.g., `v1.2.3`).
8.  **Promotion**: Versioned tags can then be deployed to `stg` and `prod` environments via manual trigger of the `Infrastructure Provision` workflow.

## 5. Summary Deployment Lifecycle

```
┌──────────────────────────────────────────────────────────────────┐
│  1. Commit to /app → Build & Push (Auto)                         │
│     ↓                                                            │
│  2. Update image_tag in terraform.tfvars (Auto)                  │
│     ↓                                                            │
│  3. Terraform Plan for dev (Auto)                                │
│     ↓                                                            │
│  4. Terraform Apply for dev (Auto)                             │
│     ↓                                                            │
│  5. Integration tests run against Load Balancer (Auto)           │
│     ↓                                                            │
│  6. Merge release-please PR → Create version tag (MANUAL)        │
│     ↓                                                            │
│  7. Manual Deploy tag to STG → PROD (MANUAL)                     │
│     ↓                                                            │
│  ✓ Release complete                                              │
└──────────────────────────────────────────────────────────────────┘
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
