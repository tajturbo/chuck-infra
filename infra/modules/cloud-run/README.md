# Cloud Run Module

Provisions a Google Cloud Run (v2) service with standard defaults for internal applications.

## Features
- Multi-revision support
- Health check probes (startup, liveness)
- Labels for environment tracking
- Configurable manual scaling

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `project_id` | GCP Project ID | `string` | n/a | yes |
| `region` | GCP Region | `string` | n/a | yes |
| `name` | Service name | `string` | n/a | yes |
| `container_image` | Docker image to deploy | `string` | n/a | yes |
| `environment` | Environment label (dev/stg/prod) | `string` | n/a | yes |
| `min_instances` | Minimum number of instances | `number` | `0` | no |
| `max_instances` | Maximum number of instances | `number` | `10` | no |

## Outputs

| Name | Description |
|------|-------------|
| `service_id` | Full resource ID of the Cloud Run service |
| `service_url` | Default assigned service URL |
| `service_name` | Short name of the service |
