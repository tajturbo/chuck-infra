# Project Context

## Purpose
DevOps test exercise: Build a full-stack Python application that displays Chuck Norris jokes from [api.chucknorris.io](https://api.chucknorris.io/), containerized with Docker, deployed to GCP with zero-downtime, fully automated via GitHub Actions.

## Tech Stack
- **Application**: Python 3.12, Flask/Gunicorn
- **Frontend**: HTML/CSS (Jinja2 templates)
- **Container**: Docker (Alpine Linux base)
- **Web Proxy**: Nginx (reverse proxy)
- **Infrastructure**: Terraform (GCP)
- **CI/CD**: GitHub Actions
- **Cloud**: GCP (Cloud Run, Load Balancer, Artifact Registry)
- **Testing**: pytest (unit), integration tests

## Project Structure
```
/app          - Python application + Dockerfile
/infra        - Terraform infrastructure code
/docs         - Documentation
/.github      - GitHub Actions workflows
```

## Project Conventions

### Code Style
- Python: PEP 8, Black formatter, isort for imports
- Terraform: terraform fmt, consistent naming
- YAML: 2-space indentation

### Architecture Patterns
- 3-tier: Load Balancer → Cloud Run (2 zones) → External API
- Infrastructure as Code (Terraform)
- GitOps: separate workflows for infra and app deployment
- Environment promotion: dev → stg → prod

### Testing Strategy
- **Unit tests**: pytest for Python application logic
- **Integration tests**: Validate deployed endpoints respond correctly
- **Health checks**: Container-level health endpoints

### Git Workflow
- Trunk-based development with feature branches
- Conventional Commits
- Protected main branch with PR reviews

## Domain Context
- Chuck Norris jokes fetched from `https://api.chucknorris.io/jokes/random`
- Application renders HTML page with joke content
- Zero-downtime deployments using Cloud Run revisions

## Important Constraints
- Must use vanilla Alpine Linux as Docker base image
- Must deploy to 2 zones for redundancy
- Must support dev/stg/prod environments
- Zero-downtime deployment required

## External Dependencies
- [Chuck Norris API](https://api.chucknorris.io/) - External jokes API
- GCP Services: Cloud Run, Load Balancer, Artifact Registry, Cloud DNS
- GitHub Container Registry (optional) or GCP Artifact Registry
