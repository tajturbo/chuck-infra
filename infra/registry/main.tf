# Global Artifact Registry
# This is shared across all environments (dev/stg/prod)
# Run this module separately to create the shared registry

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # GCS backend for remote state (configured via -backend-config in GHA)
  backend "gcs" {}
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region for the registry"
  type        = string
  default     = "us-central1"
}

# Enable Artifact Registry API
resource "google_project_service" "artifactregistry" {
  project            = var.project_id
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

# Global Docker Registry (shared across all environments)
resource "google_artifact_registry_repository" "chuck_registry" {
  project       = var.project_id
  location      = var.region
  repository_id = "chuck-registry"
  description   = "Docker repository for Chuck Norris app (all environments)"
  format        = "DOCKER"

  cleanup_policies {
    id     = "keep-minimum-versions"
    action = "KEEP"
    most_recent_versions {
      keep_count = 20
    }
  }

  labels = {
    app        = "chuck-norris"
    managed_by = "terraform"
  }

  depends_on = [google_project_service.artifactregistry]
}

output "repository_url" {
  description = "Full repository URL for docker push"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.chuck_registry.repository_id}"
}

output "repository_id" {
  description = "Repository ID"
  value       = google_artifact_registry_repository.chuck_registry.repository_id
}
