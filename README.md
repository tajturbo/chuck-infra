# Chuck Norris Jokes Application

A full-stack Python application that displays Chuck Norris jokes, containerized with Docker and deployed to GCP with zero-downtime deployments.

## 🚀 Quick Start

### Prerequisites
- Python 3.12+
- Docker
- GCP account with billing enabled
- Terraform 1.5+
- GitHub repository (for CI/CD)

### Local Development

```bash
# Run the app locally
cd app
pip install -r requirements.txt
python app.py
# Open http://localhost:8000
```

### Docker Build

```bash
cd app
docker build -t chuck-app .
docker run -p 8080:8000 chuck-app
# Open http://localhost:8080
```

## 📁 Project Structure

```
├── app/                    # Python application
│   ├── app.py              # Flask application
│   ├── templates/          # HTML templates
│   ├── test_app.py         # Unit tests
│   ├── Dockerfile          # Container definition
│   └── requirements.txt    # Python dependencies
├── infra/                  # Terraform infrastructure
│   ├── main.tf, variables.tf, resources.tf, outputs.tf
│   ├── modules/cloud-run/  # Cloud Run service
│   ├── modules/load-balancer/
│   └── registry/           # Global Docker registry
├── .github/workflows/      # CI/CD pipelines
│   ├── docker-build.yml    # Build and push images
│   ├── release-please.yml  # Automatic versioning
│   ├── deploy-from-tag.yml # Deploy releases to stg/prod
│   ├── app-deploy.yml      # Zero-downtime deployment
│   └── infra-provision.yml # Terraform provisioning
└── docs/                   # Documentation
```

## 🔄 Release Workflow

This project uses **Conventional Commits** and **release-please** for automatic versioning.

```
main branch ──► Auto-deploy to DEV
     │
     └──► release-please creates Release PR
              │
              └──► Merge PR → Creates tag (v1.0.0)
                        │
                        └──► Deploy to STG (automatic)
                                  │
                                  └──► Deploy to PROD (manual)
```

## 🔧 Architecture

```
┌─────────────────┐
│   GitHub        │
│   Actions       │
└───────┬─────────┘
        │ Deploy
        ▼
┌─────────────────┐     ┌─────────────────┐
│ Artifact        │     │ Load Balancer   │
│ Registry        │     │ (Global HTTPS)  │
└───────┬─────────┘     └───────┬─────────┘
        │                       │
        └───────────┬───────────┘
                    │
        ┌───────────┴───────────┐
        │                       │
        ▼                       ▼
┌─────────────────┐     ┌─────────────────┐
│ Cloud Run       │     │ Cloud Run       │
│ (us-central1)   │     │ (us-east1)      │
└─────────────────┘     └─────────────────┘
```

- **Multi-region**: Deployed to 2 GCP regions for redundancy
- **Zero-downtime**: Canary deployments with gradual traffic shift
- **Auto-scaling**: 0 to N instances based on traffic

## 🔐 GCP Setup

### 1. Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `GCP_PROJECT_ID` | Your GCP project ID |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Workload Identity Provider |
| `GCP_SERVICE_ACCOUNT` | Service account email |
| `TF_STATE_BUCKET` | GCS bucket for Terraform state |

### 2. Service Account Permissions

```bash
# Create service account
gcloud iam service-accounts create chuck-deployer \
  --display-name="Chuck Norris Deployer"

# Grant permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:chuck-deployer@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:chuck-deployer@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:chuck-deployer@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/compute.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:chuck-deployer@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"
```

### 3. Workload Identity Federation

See [docs/deployment-guide.md](docs/deployment-guide.md) for detailed setup.

## 📦 Deployment

### Initial Setup

1. **Create Docker Registry** (one-time):
   ```bash
   cd infra/registry
   terraform init -backend-config="bucket=YOUR_BUCKET" -backend-config="prefix=chuck-registry"
   terraform apply -var="project_id=YOUR_PROJECT"
   ```

2. **Provision Infrastructure** (per environment):
   - Go to GitHub Actions
   - Run "Infrastructure Provision" workflow
   - Select environment: dev, stg, or prod
   - Action: plan (to review), then apply

3. **Deploy Application**:
   - Push to main branch (auto-deploys to dev)
   - Or run "Deploy Application" workflow manually

### Zero-Downtime Deploy

The deploy workflow:
1. Deploys new revision with 0% traffic
2. Runs integration tests against canary
3. Shifts traffic 50%
4. Validates health
5. Shifts traffic 100%
6. Rolls back automatically on failure

## 🧪 Testing

```bash
# Unit tests
cd app
pytest test_app.py -v

# Integration tests (requires deployed environment)
# Run via GitHub Actions "Integration Tests" workflow
```

## 📄 License

MIT
