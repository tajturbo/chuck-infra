# Global Artifact Registry (managed conditionally, typically only in dev)
# This allows a shared registry pattern while keeping code consolidated

resource "google_artifact_registry_repository" "chuck_registry" {
  count = var.create_registry ? 1 : 0

  project       = var.project_id
  location      = var.region
  repository_id = "chuck-registry"
  description   = "Docker repository for Chuck Norris app (shared)"
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
    env        = var.environment
  }
}
