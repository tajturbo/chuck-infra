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

```
┌─────────────────┐
│  Developer      │
│  commits        │
└────────┬────────┘
         │ conventional commits (push to main)
         ▼
┌─────────────────┐
│  main branch    │──────► Auto-tag & GitOps Commit ──► Auto-deploy to DEV
└────────┬────────┘
         │ release-please creates PR
         ▼
┌─────────────────┐
│  Release PR     │  (auto-generated changelog)
│  merged         │
└────────┬────────┘
         │ creates tag (e.g., v1.2.0)
         ▼
┌─────────────────┐
│  Tag created    │──────► Deploy to STG
└────────┬────────┘
         │ manual promotion
         ▼
┌─────────────────┐
│  Deploy from    │──────► Deploy to PROD
│  Tag workflow   │
└─────────────────┘
```

## Environments

| Environment | Trigger | Deployment |
|-------------|---------|------------|
| **dev** | Push to `main` | Automatic |
| **stg** | Tag created | Automatic |
| **prod** | Manual (Deploy from Tag) | Manual approval |

## Branch Strategy

- `main` - Development branch, auto-deploys to dev
- Feature branches - Create PRs to main
- No direct commits to main (use PRs)
