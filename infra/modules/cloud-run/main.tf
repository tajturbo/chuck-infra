# Cloud Run Service Module
# Deploys a container to Cloud Run with manual scaling and traffic management

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "name" {
  description = "Service name"
  type        = string
}

variable "container_image" {
  description = "Container image to deploy"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "desired_instances" {
  description = "Fixed number of instances (manual scaling)"
  type        = number
  default     = 1
}

variable "cpu" {
  description = "CPU allocation"
  type        = string
  default     = "1"
}

variable "memory" {
  description = "Memory allocation"
  type        = string
  default     = "256Mi"
}

# Cloud Run Service (using v2 API for better traffic management)
resource "google_cloud_run_v2_service" "service" {
  name     = var.name
  location = var.region
  project  = var.project_id

  template {
    containers {
      image = var.container_image

      ports {
        container_port = 8000
      }

      resources {
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
        cpu_idle = true
      }

      startup_probe {
        http_get {
          path = "/health"
          port = 8000
        }
        initial_delay_seconds = 5
        timeout_seconds       = 3
        period_seconds        = 5
        failure_threshold     = 3
      }

      liveness_probe {
        http_get {
          path = "/health"
          port = 8000
        }
        initial_delay_seconds = 10
        timeout_seconds       = 3
        period_seconds        = 30
        failure_threshold     = 3
      }
    }

    scaling {
      scaling_mode          = "MANUAL"
      manual_instance_count = var.desired_instances
    }

    labels = {
      environment = var.environment
      app         = "chuck-norris"
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  labels = {
    environment = var.environment
    app         = "chuck-norris"
    managed_by  = "terraform"
  }

  lifecycle {
    ignore_changes = [
      # Allow the deployment workflow to manage traffic splitting
      traffic,
      client,
      client_version,
    ]
  }
}

# Allow unauthenticated access (public app)
resource "google_cloud_run_v2_service_iam_member" "public" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.service.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

output "service_url" {
  description = "Cloud Run service URL"
  value       = google_cloud_run_v2_service.service.uri
}

output "service_id" {
  description = "Cloud Run service ID"
  value       = google_cloud_run_v2_service.service.id
}

output "service_name" {
  description = "Cloud Run service name"
  value       = google_cloud_run_v2_service.service.name
}

output "latest_revision" {
  description = "Latest revision name"
  value       = google_cloud_run_v2_service.service.latest_ready_revision
}
