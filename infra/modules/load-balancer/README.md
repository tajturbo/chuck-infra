# Load Balancer Module

Configures a Global external HTTP(S) Load Balancer (Classic) for Cloud Run backends.

## Features
- Global External IP reservation
- Google-managed SSL Certificate
- HTTP to HTTPS redirect
- Serverless NEGs for Cloud Run
- Explicit URL mapping with path matchers

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `project_id` | GCP Project ID | `string` | n/a | yes |
| `name` | LB resource name prefix | `string` | n/a | yes |
| `environment` | Environment label | `string` | n/a | yes |
| `backend_services` | Map of backends (region, service_id) | `map` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| `ip_address` | Static Global IP address |
| `https_url` | Formatted HTTPS URL (using nip.io for demo) |
