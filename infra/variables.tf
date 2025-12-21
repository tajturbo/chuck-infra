# Variables for Chuck Norris Infrastructure
# All values set via GHA workflow for different environments

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "Primary GCP region"
  type        = string
  default     = "us-central1"
}

variable "secondary_region" {
  description = "Secondary GCP region for redundancy"
  type        = string
  default     = "us-east1"
}

variable "environment" {
  description = "Environment name (dev, stg, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "stg", "prod"], var.environment)
    error_message = "Environment must be one of: dev, stg, prod"
  }
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

# Scaling configuration per environment
variable "min_instances" {
  description = "Minimum number of instances"
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Maximum number of instances"
  type        = number
  default     = 10
}

# FinOps configuration
variable "finops_schedule_enabled" {
  description = "Enable automated start/stop schedule for this environment"
  type        = bool
  default     = false
}

variable "finops_timezone" {
  description = "Timezone for the FinOps schedule"
  type        = string
  default     = "Europe/Prague" # CET/CEST
}
