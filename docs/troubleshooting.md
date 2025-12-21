# Troubleshooting & Operations Runbook

A guide for diagnosing and resolving common issues with the Chuck Norris Jokes infrastructure.

## 🚨 Emergency Actions

### 1. Manual Rollback
If a deployment is unstable, you can shift traffic back to the previous revision immediately.

```bash
# Set variables
ENV="dev"     # or stg, prod
REGION="us-central1"
SERVICE="chuck-${ENV}-primary"

# List revisions to find the stable one
gcloud run revisions list --service=$SERVICE --region=$REGION

# Shift 100% traffic to stable revision
gcloud run services update-traffic $SERVICE \
  --region=$REGION \
  --to-revisions=STABLE_REVISION_NAME=100
```

### 2. Emergency Scale Up
If the application is under heavy load and manual scaling needs adjustment.

```bash
gcloud run services update chuck-dev-primary \
  --region=us-central1 \
  --min-instances=5 \
  --max-instances=50
```

## 🔍 Common Issues

### "Repository Not Found" in CI/CD
**Symptom**: `git push` fails with `fatal: repository ... not found`.
**Fix**:
1. Check if the `PAT_TOKEN` secret is valid and has `repo` and `workflow` scopes.
2. Ensure the repository URL is correct in the workflow (`origin` remote).
3. Verify that the GitHub Actions bot has `write` permissions on `contents`.

### SSL Certificate Stuck in "PROVISIONING"
**Symptom**: HTTPS URL doesn't work after 30+ minutes.
**Fix**:
1. Global SSL certificates can take up to 60 minutes.
2. Verify that the `nip.io` domain points correctly to the Load Balancer IP:
   ```bash
   ping <lb-ip>.nip.io
   ```
3. Check the certificate status:
   ```bash
   gcloud compute ssl-certificates describe chuck-dev-cert --global
   ```

### 502/503 Service Unavailable
**Symptom**: Accessing LB IP returns 502 or 503.
**Fix**:
1. **Cloud Run Health**: Check if the container starts correctly.
   ```bash
   gcloud run services logs read ...
   ```
2. **NEG Status**: Ensure the Serverless NEG is associated with the Backend Service.
3. **Port Mismatch**: Verify the container listens on port **8000** and the LB health check is also on **8000**.

## 📊 Useful Commands
- **View Logs**: `gcloud run services logs read chuck-dev-primary`
- **Check Traffic**: `gcloud run services describe chuck-dev-primary --format='value(status.traffic)'`
- **Inspect LB Backend**: `gcloud compute backend-services get-health chuck-dev-backend --global`
