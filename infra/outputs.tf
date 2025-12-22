# Outputs

output "artifact_registry_url" {
  description = "Artifact Registry URL for pushing images"
  value       = local.artifact_repo
}

output "cloud_run_primary_url" {
  description = "Primary Cloud Run service URL"
  value       = module.cloud_run_primary.service_url
}

output "cloud_run_secondary_url" {
  description = "Secondary Cloud Run service URL"
  value       = module.cloud_run_secondary.service_url
}

output "load_balancer_ip" {
  description = "Load Balancer IP address"
  value       = module.load_balancer.ip_address
}

output "load_balancer_url" {
  description = "Load Balancer URL"
  value       = module.load_balancer.https_url
}

output "environment" {
  description = "Deployed environment"
  value       = var.environment
}
