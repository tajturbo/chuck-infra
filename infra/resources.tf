# Resource definitions
# Resources named chuck-${env} for multi-environment support in same account

locals {
  name_prefix = "chuck-${var.environment}"
  # Global registry (shared across all environments)
  registry_name   = "chuck-registry"
  artifact_repo   = "${var.region}-docker.pkg.dev/${var.project_id}/${local.registry_name}"
  container_image = "${local.artifact_repo}/app:${var.image_tag}"
}

# Enable required APIs
resource "google_project_service" "apis" {
  for_each = toset([
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "compute.googleapis.com",
    "cloudscheduler.googleapis.com",
    "cloudfunctions.googleapis.com",
    "pubsub.googleapis.com",
    "cloudbuild.googleapis.com", # Required for Cloud Functions Gen2
    "eventarc.googleapis.com",   # Required for Cloud Functions Gen2 triggers
  ])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

# Cloud Run - Primary Region
module "cloud_run_primary" {
  source = "./modules/cloud-run"

  project_id      = var.project_id
  region          = var.region
  name            = "${local.name_prefix}-primary"
  container_image = local.container_image
  environment     = var.environment
  min_instances   = var.min_instances
  max_instances   = var.max_instances

  depends_on = [google_project_service.apis]
}

# Cloud Run - Secondary Region (for redundancy)
module "cloud_run_secondary" {
  source = "./modules/cloud-run"

  project_id      = var.project_id
  region          = var.secondary_region
  name            = "${local.name_prefix}-secondary"
  container_image = local.container_image
  environment     = var.environment
  min_instances   = var.min_instances
  max_instances   = var.max_instances

  depends_on = [google_project_service.apis]
}

# Load Balancer
module "load_balancer" {
  source = "./modules/load-balancer"

  project_id  = var.project_id
  name        = local.name_prefix
  environment = var.environment

  backend_services = {
    primary = {
      region     = var.region
      service_id = module.cloud_run_primary.service_id
    }
    secondary = {
      region     = var.secondary_region
      service_id = module.cloud_run_secondary.service_id
    }
  }

  depends_on = [module.cloud_run_primary, module.cloud_run_secondary]
}
