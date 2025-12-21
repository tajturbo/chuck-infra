# Chuck Norris Jokes Application

[![Docker Build and Push](https://github.com/tajturbo/chuck-infra/actions/workflows/docker-build.yml/badge.svg)](https://github.com/tajturbo/chuck-infra/actions/workflows/docker-build.yml)
[![Infrastructure Provision](https://github.com/tajturbo/chuck-infra/actions/workflows/infra-provision.yml/badge.svg)](https://github.com/tajturbo/chuck-infra/actions/workflows/infra-provision.yml)

A full-stack Python application that displays Chuck Norris jokes, containerized with Docker and deployed to GCP with zero-downtime deployments.

## 🌐 Environments

| Environment | Status | URL |
|-------------|--------|-----|
| **Development** | ![Success](https://img.shields.io/badge/status-active-success) | [https://136.110.212.221.nip.io](https://136.110.212.221.nip.io) |
| **Staging** | ![Success](https://img.shields.io/badge/status-active-success) | [https://35.244.233.10.nip.io](https://35.244.233.10.nip.io) |
| **Production** | ![Pending](https://img.shields.io/badge/status-pending-lightgrey) | [https://chuck.tajturbo.com](https://chuck.tajturbo.com) |

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
│   └── modules/load-balancer/
├── .github/workflows/      # CI/CD pipelines
│   ├── docker-build.yml    # Build, push, and update image tag
│   ├── release-please.yml  # Automatic versioning
│   ├── integration-tests.yml # Automated LB-centric tests
│   └── infra-provision.yml # Terraform provisioning (Dev/Stg/Prod)
└── docs/                   # Documentation
```

For a detailed breakdown of the release process, see [CONTRIBUTING.md](CONTRIBUTING.md) and the **[Deployment Guide](docs/deployment-guide.md)**. For first-time environment setup, refer to the **[Initial Setup Guide](docs/initial-setup.md)**.

## 🔧 Architecture

The application uses a multi-region, high-availability architecture on GCP.

- **Multi-region**: Deployed to `us-central1` and `us-east1` for maximum redundancy.
- **Zero-downtime**: Leverages Cloud Run's native revision management for safe deployments.
- **Manual scaling**: Fixed to 1 instance per region (scalable via Terraform).

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
