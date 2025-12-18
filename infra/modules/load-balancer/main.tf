# Global Load Balancer Module
# Creates an HTTPS load balancer with Cloud Run backends

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "name" {
  description = "Load balancer name prefix"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "backend_services" {
  description = "Map of backend services with region and service_id"
  type = map(object({
    region     = string
    service_id = string
  }))
}

# Reserve a global external IP address
resource "google_compute_global_address" "default" {
  project = var.project_id
  name    = "${var.name}-ip"
}

# Serverless NEG for each Cloud Run service
resource "google_compute_region_network_endpoint_group" "neg" {
  for_each = var.backend_services

  project               = var.project_id
  name                  = "${var.name}-neg-${each.key}"
  network_endpoint_type = "SERVERLESS"
  region                = each.value.region

  cloud_run {
    service = split("/", each.value.service_id)[length(split("/", each.value.service_id)) - 1]
  }
}

# Backend service
resource "google_compute_backend_service" "default" {
  project = var.project_id
  name    = "${var.name}-backend"

  protocol              = "HTTP"
  port_name             = "http"
  timeout_sec           = 30
  load_balancing_scheme = "EXTERNAL_MANAGED"

  dynamic "backend" {
    for_each = google_compute_region_network_endpoint_group.neg
    content {
      group = backend.value.id
    }
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

# URL map
resource "google_compute_url_map" "default" {
  project         = var.project_id
  name            = "${var.name}-url-map"
  default_service = google_compute_backend_service.default.id

  default_route_action {
    weighted_backend_services {
      backend_service = google_compute_backend_service.default.id
      weight          = 100
    }
  }
}

# Managed SSL certificate (using nip.io for easy setup)
resource "google_compute_managed_ssl_certificate" "default" {
  project = var.project_id
  name    = "${var.name}-cert"

  managed {
    domains = ["${google_compute_global_address.default.address}.nip.io"]
  }
}

# HTTPS proxy
resource "google_compute_target_https_proxy" "default" {
  project          = var.project_id
  name             = "${var.name}-https-proxy"
  url_map          = google_compute_url_map.default.id
  ssl_certificates = [google_compute_managed_ssl_certificate.default.id]
}

# HTTP proxy (for redirect)
resource "google_compute_target_http_proxy" "default" {
  project = var.project_id
  name    = "${var.name}-http-proxy"
  url_map = google_compute_url_map.http_redirect.id
}

# URL map for HTTP to HTTPS redirect
resource "google_compute_url_map" "http_redirect" {
  project = var.project_id
  name    = "${var.name}-http-redirect"

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

# Global forwarding rule for HTTPS
resource "google_compute_global_forwarding_rule" "https" {
  project               = var.project_id
  name                  = "${var.name}-https-rule"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_target_https_proxy.default.id
  ip_address            = google_compute_global_address.default.id

  labels = {
    environment = var.environment
    app         = "chuck-norris"
  }
}

# Global forwarding rule for HTTP (redirect to HTTPS)
resource "google_compute_global_forwarding_rule" "http" {
  project               = var.project_id
  name                  = "${var.name}-http-rule"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80"
  target                = google_compute_target_http_proxy.default.id
  ip_address            = google_compute_global_address.default.id

  labels = {
    environment = var.environment
    app         = "chuck-norris"
  }
}

output "ip_address" {
  description = "Load balancer IP address"
  value       = google_compute_global_address.default.address
}

output "https_url" {
  description = "HTTPS URL for the load balancer"
  value       = "https://${google_compute_global_address.default.address}.nip.io"
}
