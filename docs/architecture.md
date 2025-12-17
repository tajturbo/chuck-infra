# Architecture Documentation

## System Overview

The Chuck Norris Jokes application is a Python Flask web application deployed to Google Cloud Platform using a multi-region, high-availability architecture.

## Architecture Diagram

```
                                    ┌─────────────────────┐
                                    │     GitHub          │
                                    │     Repository      │
                                    └──────────┬──────────┘
                                               │
                              ┌────────────────┴────────────────┐
                              │         GitHub Actions          │
                              │  ┌──────────────────────────┐   │
                              │  │ • Build & Test           │   │
                              │  │ • Docker Push            │   │
                              │  │ • Terraform Apply        │   │
                              │  │ • Zero-downtime Deploy   │   │
                              │  └──────────────────────────┘   │
                              └────────────────┬────────────────┘
                                               │
                    ┌──────────────────────────┴──────────────────────────┐
                    │                      GCP                            │
                    │                                                     │
                    │   ┌─────────────────────────────────────────────┐   │
                    │   │           Artifact Registry                  │   │
                    │   │           (chuck-registry)                   │   │
                    │   │           Docker images shared               │   │
                    │   │           across all environments            │   │
                    │   └─────────────────────────────────────────────┘   │
                    │                                                     │
                    │   ┌─────────────────────────────────────────────┐   │
                    │   │         Global HTTPS Load Balancer          │   │
                    │   │         • Managed SSL certificate           │   │
                    │   │         • HTTP → HTTPS redirect             │   │
                    │   │         • Health checks                     │   │
                    │   └───────────────────┬─────────────────────────┘   │
                    │                       │                             │
                    │           ┌───────────┴───────────┐                 │
                    │           │                       │                 │
                    │   ┌───────▼───────┐       ┌───────▼───────┐         │
                    │   │  Cloud Run    │       │  Cloud Run    │         │
                    │   │  us-central1  │       │  us-east1     │         │
                    │   │               │       │               │         │
                    │   │  chuck-{env}- │       │  chuck-{env}- │         │
                    │   │  primary      │       │  secondary    │         │
                    │   └───────────────┘       └───────────────┘         │
                    │                                                     │
                    └─────────────────────────────────────────────────────┘
                                               │
                                               ▼
                                    ┌─────────────────────┐
                                    │   Chuck Norris API  │
                                    │ api.chucknorris.io  │
                                    └─────────────────────┘
```

## Components

### Application Layer

| Component | Technology | Purpose |
|-----------|------------|---------|
| Web Server | Nginx | Reverse proxy, SSL termination, compression |
| App Server | Gunicorn | WSGI server for Python |
| Framework | Flask | Web framework |
| Process Manager | Supervisor | Manages Nginx + Gunicorn |

### Infrastructure Layer

| Component | GCP Service | Purpose |
|-----------|-------------|---------|
| Container Registry | Artifact Registry | Docker image storage |
| Compute | Cloud Run | Serverless containers |
| Load Balancing | Global HTTP(S) LB | Traffic distribution |
| DNS | Cloud DNS (optional) | Domain management |

### CI/CD Layer

| Workflow | Trigger | Actions |
|----------|---------|---------|
| docker-build | Push to main | Test → Build → Push |
| infra-provision | Manual | Terraform plan/apply/destroy |
| app-deploy | After build | Zero-downtime deploy |
| integration-tests | Manual/Called | Validate deployment |

## Deployment Strategies

### Zero-Downtime Deployment

```
Time    Traffic Distribution
─────   ────────────────────────
T+0     [████████████] 100% Old
T+1     [████████████] 100% Old → Deploy new (0% traffic)
T+2     [██████      ] 50% Old / 50% New
T+3     [            ] 0% Old / 100% New
```

### Rollback Strategy

Automatic rollback on:
- Integration test failure
- Health check failure
- Deployment error

Manual rollback via:
- GitHub Actions workflow
- `gcloud run services update-traffic`

## Resource Naming Convention

All resources follow the pattern: `chuck-{environment}`

| Environment | Example Resources |
|-------------|-------------------|
| dev | chuck-dev-primary, chuck-dev-secondary |
| stg | chuck-stg-primary, chuck-stg-secondary |
| prod | chuck-prod-primary, chuck-prod-secondary |

Shared resources:
- `chuck-registry` (Artifact Registry, shared across all envs)

## Scaling Configuration

| Environment | Min Instances | Max Instances |
|-------------|---------------|---------------|
| dev | 0 | 2 |
| stg | 0 | 5 |
| prod | 1 | 100 |

Cloud Run automatically scales based on:
- Request concurrency (default: 80)
- CPU utilization
- Memory utilization

## Security

- **Authentication**: Workload Identity Federation (keyless)
- **Network**: HTTPS only, HTTP redirects
- **IAM**: Least privilege service accounts
- **Secrets**: GitHub Secrets, no hardcoded credentials
