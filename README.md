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
│   ├── docker-build.yml    # Build, push, and update image tag
│   ├── release-please.yml  # Automatic versioning
│   ├── integration-tests.yml # Automated LB-centric tests
│   └── infra-provision.yml # Terraform provisioning (Dev/Stg/Prod)
└── docs/                   # Documentation
```

## 🔄 Release Workflow

This project uses **Conventional Commits** and **release-please** for automatic versioning. The workflow follows these steps:
1. **Automated Build**: Commits to `/app` trigger tests, builds, and automated tag updates in Terraform.
2. **Manual Deployment**: Infrastructure updates (Dev/Stg/Prod) are triggered manually via GitHub Actions.
3. **Automated Validation**: After deployment, integration tests run automatically against the Load Balancer.

For a detailed breakdown, see [CONTRIBUTING.md](CONTRIBUTING.md) and the [Deployment Guide](docs/deployment-guide.md).

## 🔧 Architecture

The application uses a multi-region, high-availability architecture on GCP.

- **Multi-region**: Deployed to `us-central1` and `us-east1` for maximum redundancy.
- **Zero-downtime**: Leverages Cloud Run's native revision management for safe deployments.
- **Auto-scaling**: Scales from 0 to 10+ instances based on request concurrency.

See [docs/architecture.md](docs/architecture.md) for detailed diagrams.

## 🔐 GCP Setup & Deployment

Setting up the infrastructure requires specific GCP roles and GitHub secrets.

1. **Authentication**: Uses Workload Identity Federation (keyless).
2. **Infrastructure**: Provisioned via Terraform.
3. **Deployment**: Automated via GitHub Actions.

Refer to the [Deployment Guide](docs/deployment-guide.md) for step-by-step instructions on:
- Service Account setup
- Workload Identity Federation configuration
- GitHub Secrets definitions
- Initial provisioning and deployment tasks

For operational details and troubleshooting, see:
- [API Reference](docs/api-reference.md)
- [Troubleshooting & Runbook](docs/troubleshooting.md)

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
