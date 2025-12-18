# Contributing Guidelines

## Commit Message Convention

This project uses [Conventional Commits](https://www.conventionalcommits.org/) for automatic versioning and changelog generation.

### Format

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Types

| Type | Description | Version Bump |
|------|-------------|--------------|
| `feat` | New feature | Minor (0.x.0) |
| `fix` | Bug fix | Patch (0.0.x) |
| `docs` | Documentation only | None |
| `style` | Code style (formatting) | None |
| `refactor` | Code refactoring | None |
| `perf` | Performance improvement | Patch |
| `test` | Adding tests | None |
| `chore` | Maintenance tasks | None |
| `ci` | CI/CD changes | None |

### Breaking Changes

Add `!` after type or `BREAKING CHANGE:` in footer for major version bumps:

```
feat!: remove deprecated API endpoint

BREAKING CHANGE: The /v1/jokes endpoint has been removed
```

### Examples

```bash
# Feature
git commit -m "feat(app): add joke categories filter"

# Bug fix
git commit -m "fix(api): handle empty response from Chuck Norris API"

# Documentation
git commit -m "docs: update deployment guide with new secrets"

# Infrastructure
git commit -m "chore(infra): update Cloud Run memory limits"

# Breaking change
git commit -m "feat(api)!: change joke response format"
```

## Release Workflow

```mermaid
graph TD
    A[Commit to /app] -->|automated| B[Tests & Image Build]
    B -->|automated| C[Push to Registry]
    C -->|automated| D[Update infra/terraform.tfvars]
    D -->|manual| E[Terraform Plan - dev]
    E -->|manual| F[Terraform Apply - dev]
    F -->|automated| G[Integration Tests]
    G -->|manual| H[Merge Release-Please PR]
    H -->|automated| I[Create v* Tag]
    I -->|manual| J[Deploy to stg/prod with release tag]
```

For detailed information on environment triggers, mode of operation, and naming conventions, please refer to the **[Environments & Conventions](docs/architecture.md#environments--conventions)** section in the architecture documentation.

## Branch Strategy

- `main` - Development branch, auto-deploys to dev
- Feature branches - Create PRs to main
- No direct commits to main (use PRs)
