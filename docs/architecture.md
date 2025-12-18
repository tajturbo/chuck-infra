# Architecture Documentation

## System Overview

The Chuck Norris Jokes application is a Python Flask web application deployed to Google Cloud Platform using a multi-region, high-availability architecture.

## Architecture Diagram

```mermaid
graph TB
    Internet([Internet]) --> LB[Global HTTPS Load Balancer]
    
    subgraph "GCP Infrastructure"
        LB --> NEG1[Serverless NEG - us-central1]
        LB --> NEG2[Serverless NEG - us-east1]
        
        NEG1 --> CR1[Cloud Run Primary]
        NEG2 --> CR2[Cloud Run Secondary]
        
        CR1 --> AR[Artifact Registry]
        CR2 --> AR
    end
    
    subgraph "External"
        CR1 -.-> API[Chuck Norris API]
        CR2 -.-> API
    end

    style LB fill:#f9f,stroke:#333,stroke-width:2px
    style AR fill:#bbf,stroke:#333
    style CR1 fill:#dfd,stroke:#333
    style CR2 fill:#dfd,stroke:#333
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

### Zero-Downtime Deployment (Canary)

The deployment workflow uses Cloud Run revisions for safe, gradual traffic shifting:

1.  **Deployment**: A new revision is deployed with 0% traffic.
2.  **Validation**: Integration tests are run against the unique URL of the new revision (canary).
3.  **Traffic Shift**: 
    - Shift 50% traffic if tests pass.
    - Monitor health and latency.
    - Shift 100% traffic if stable.
4.  **Automatic Rollback**: If any stage fails (tests or health check), traffic is reverted to the previous stable revision.

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
