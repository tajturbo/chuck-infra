# FinOps: Automated Start/Stop for Non-Prod Infrastructure
# This file defines the Cloud Function and Scheduler jobs for cost optimization

# Zip file for Cloud Function source
data "archive_file" "finops_source" {
  count       = var.finops_schedule_enabled ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/functions/scale-resources"
  output_path = "${path.module}/functions/scale-resources.zip"
}

# Bucket for Cloud Function source
resource "google_storage_bucket" "finops_source_bucket" {
  count                       = var.finops_schedule_enabled ? 1 : 0
  name                        = "${var.project_id}-finops-source-${var.environment}"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
}

resource "google_storage_bucket_object" "finops_zip" {
  count  = var.finops_schedule_enabled ? 1 : 0
  name   = "source-${data.archive_file.finops_source[0].output_md5}.zip"
  bucket = google_storage_bucket.finops_source_bucket[0].name
  source = data.archive_file.finops_source[0].output_path
}

# Pub/Sub Topic to trigger the function
resource "google_pubsub_topic" "finops_trigger" {
  count = var.finops_schedule_enabled ? 1 : 0
  name  = "finops-scale-${var.environment}"
}

# Service Account for Cloud Function (Managed in setup-wif.sh)
data "google_service_account" "finops_sa" {
  count      = var.finops_schedule_enabled ? 1 : 0
  account_id = "chuck-finops-${var.environment}"
}

# Cloud Function (Gen2)
resource "google_cloudfunctions2_function" "scale_resources" {
  count       = var.finops_schedule_enabled ? 1 : 0
  name        = "scale-resources-${var.environment}"
  location    = var.region
  description = "Scales Cloud Run services for FinOps"

  build_config {
    runtime     = "python310"
    entry_point = "scale_cloud_run"
    source {
      storage_source {
        bucket = google_storage_bucket.finops_source_bucket[0].name
        object = google_storage_bucket_object.finops_zip[0].name
      }
    }
  }

  service_config {
    max_instance_count    = 1
    available_memory      = "256Mi"
    timeout_seconds       = 60
    service_account_email = data.google_service_account.finops_sa[0].email
    environment_variables = {
      WAKE_MIN_INSTANCES = tostring(var.desired_instances)
      WAKE_MAX_INSTANCES = tostring(var.desired_instances)
      # Target both regions from one controller function.
      GCP_REGIONS = "${var.region},${var.secondary_region}"
      GCP_PROJECT = var.project_id
      # Only manage the two app services created by this stack.
      TARGET_SERVICE_IDS = "chuck-${var.environment}-primary,chuck-${var.environment}-secondary"
      # Keep ingress type as ALL at all times.
      SLEEP_INGRESS = "INGRESS_TRAFFIC_ALL"
      WAKE_INGRESS  = "INGRESS_TRAFFIC_ALL"
    }
  }

  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.finops_trigger[0].id
    retry_policy   = "RETRY_POLICY_RETRY"
  }

  depends_on = [google_project_service.apis]
}

# Cloud Scheduler Jobs
resource "google_cloud_scheduler_job" "sleep_infra" {
  count       = var.finops_schedule_enabled ? 1 : 0
  name        = "sleep-infra-${var.environment}"
  description = "Makes services unreachable + scales to 0 at 17:00 UTC"
  schedule    = "0 17 * * 1-5" # Mon-Fri 17:00 UTC (18:00 CET in winter)
  time_zone   = var.finops_timezone

  pubsub_target {
    topic_name = google_pubsub_topic.finops_trigger[0].id
    data = base64encode(jsonencode({
      action      = "sleep"
      environment = var.environment
    }))
  }
}

resource "google_cloud_scheduler_job" "wake_infra" {
  count       = var.finops_schedule_enabled ? 1 : 0
  name        = "wake-infra-${var.environment}"
  description = "Restores ingress + scales to 1 at 07:00 UTC"
  schedule    = "0 7 * * 1-5" # Mon-Fri 07:00 UTC (08:00 CET in winter)
  time_zone   = var.finops_timezone

  pubsub_target {
    topic_name = google_pubsub_topic.finops_trigger[0].id
    data = base64encode(jsonencode({
      action      = "wake"
      environment = var.environment
    }))
  }
}
