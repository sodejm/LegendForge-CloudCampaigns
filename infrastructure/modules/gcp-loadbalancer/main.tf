# =============================================================================
# infrastructure/modules/gcp-loadbalancer/main.tf
# =============================================================================
# LegendForge GCP Loadbalancer module configuration for universal tabletop infrastructure supporting multiple game systems.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# =============================================================================

# --- Backend Service ---
resource "google_compute_backend_service" "foundry" {
  name             = "${var.project_name}-foundry-backend"
  protocol         = "HTTP"
  port_name        = "foundry"
  session_affinity = "CLIENT_IP" # Sticky sessions for Foundry

  health_checks = [var.health_check_id]

  backend {
    group                 = var.instance_group_id
    balancing_mode        = "RATE"
    max_rate_per_instance = 1000
  }

  # Cloud CDN configuration
  enable_cdn = var.enable_cdn

  cdn_policy {
    cache_mode                   = "CACHE_ALL_STATIC"
    client_ttl                   = 3600
    default_ttl                  = 3600
    max_ttl                      = 86400
    negative_caching             = true
    serve_while_stale            = 86400
    signed_url_cache_max_age_sec = 3600
    bypass_cache_on_request_headers {
      header_name = "Authorization"
    }
  }

  # Connection draining timeout
  connection_draining_timeout_sec = 300

  # Logging
  log_config {
    enable      = true
    sample_rate = 1.0
  }

  # Circuit breaker configuration
  circuit_breakers {
    max_connections             = 1000
    max_pending_requests        = 100
    max_requests                = 1000
    max_requests_per_connection = 2
  }

  # Outlier detection for automatic failover
  outlier_detection {
    base_ejection_time {
      seconds = 30
    }

    consecutive_errors                    = 5
    consecutive_gateway_failure           = 0
    enforcing_consecutive_errors          = 100
    enforcing_consecutive_gateway_failure = 0
    enforcing_success_rate                = 100

    interval {
      seconds = 10
    }

    max_ejection_percent        = 50
    success_rate_minimum_hosts  = 5
    success_rate_request_volume = 100
    success_rate_stdev_factor   = 1900
  }

  depends_on = [var.health_check_id]
}

# --- HTTPS redirect policy (HTTP -> HTTPS) ---
resource "google_compute_backend_service" "foundry_http_redirect" {
  name     = "${var.project_name}-foundry-http-redirect"
  protocol = "HTTP"

  health_checks = [var.health_check_id]

  # Custom health check for redirect
  backend {
    group = var.instance_group_id
  }
}

# --- URL Map ---
resource "google_compute_url_map" "foundry" {
  name            = "${var.project_name}-foundry-urlmap"
  default_service = google_compute_backend_service.foundry.id

  host_rule {
    hosts        = [var.domain_name]
    path_matcher = "foundry-paths"
  }

  path_matcher {
    name            = "foundry-paths"
    default_service = google_compute_backend_service.foundry.id

    path_rule {
      paths   = ["/modules/*", "/systems/*", "/styles/*", "/scripts/*", "/fonts/*", "/images/*"]
      service = google_compute_backend_service.foundry.id
    }

    path_rule {
      paths   = ["/socket.io/*"]
      service = google_compute_backend_service.foundry.id # Websocket goes to backend
    }
  }
}

# --- SSL Policy (TLS configuration) ---
resource "google_compute_ssl_policy" "foundry" {
  name            = "${var.project_name}-foundry-ssl-policy"
  profile         = "RESTRICTED"
  min_tls_version = "TLS_1_2"
}

# --- HTTPS Proxy ---
resource "google_compute_target_https_proxy" "foundry" {
  name             = "${var.project_name}-foundry-https-proxy"
  url_map          = google_compute_url_map.foundry.id
  ssl_certificates = [google_compute_managed_ssl_certificate.foundry.id]
  ssl_policy       = google_compute_ssl_policy.foundry.id
}

# --- HTTP Proxy (for redirect) ---
resource "google_compute_target_http_proxy" "foundry_redirect" {
  name    = "${var.project_name}-foundry-http-proxy"
  url_map = google_compute_url_map.foundry.id
}

# --- Managed SSL Certificate ---
resource "google_compute_managed_ssl_certificate" "foundry" {
  name = "${var.project_name}-foundry-cert"

  managed {
    domains = [var.domain_name]
  }
}

# --- Global Forwarding Rule for HTTPS ---
resource "google_compute_global_forwarding_rule" "foundry_https" {
  name                  = "${var.project_name}-foundry-https-rule"
  ip_version            = "IPV4"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "443"
  target                = google_compute_target_https_proxy.foundry.id
}

# --- Global Forwarding Rule for HTTP (redirect) ---
resource "google_compute_global_forwarding_rule" "foundry_http" {
  name                  = "${var.project_name}-foundry-http-rule"
  ip_version            = "IPV4"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "80"
  target                = google_compute_target_http_proxy.foundry_redirect.id
}

# --- Cloud Armor Security Policy ---
resource "google_compute_security_policy" "foundry" {
  name        = "${var.project_name}-foundry-armor"
  description = "Cloud Armor policy for LegendForge (DDoS, rate limiting, WAF) with multi-system support."

  # Default rule (allow)
  rule {
    action   = "allow"
    priority = "65535"
    match {
      expr {
        expression = "true"
      }
    }
    description = "Default rule"
  }

  # Rate limiting: Max 100 requests per minute per IP
  rule {
    action   = "rate_based_ban"
    priority = "1000"
    match {
      expr {
        expression = "true"
      }
    }
    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"

      enforce_on_key      = "IP"
      enforce_on_key_name = ""
      ban_duration_sec    = 600

      rate_limit_threshold {
        count        = 100
        interval_sec = 60
      }
    }
    description = "Rate limiting: 100 req/min per IP"
  }

  # GeoIP blocking (optional)
  # rules {
  #   action   = "deny(403)"
  #   priority = "2000"
  #   match {
  #     expr {
  #       expression = "origin.region_code == 'CN' || origin.region_code == 'RU'"
  #     }
  #   }
  #   description = "Block China, Russia"
  # }

  # SQL injection detection
  rule {
    action   = "deny(403)"
    priority = "3000"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('sqli-v33-stable')"
      }
    }
    description = "SQL injection detection"
  }

  # XSS detection
  rule {
    action   = "deny(403)"
    priority = "3100"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('xss-v33-stable')"
      }
    }
    description = "XSS detection"
  }

  # Adaptive Protection (experimental)
  adaptive_protection_config {
    layer_7_ddos_defense_config {
      enable = var.enable_adaptive_protection
    }
  }

  advanced_options_config {
    json_parsing            = "STANDARD"
    log_level               = "VERBOSE"
    user_ip_request_headers = []
  }
}

# --- Attach Cloud Armor to backend service ---
resource "google_compute_backend_service" "foundry_with_armor" {
  name            = "${var.project_name}-foundry-backend-armor"
  protocol        = "HTTP"
  security_policy = google_compute_security_policy.foundry.id

  backend {
    group = var.instance_group_id
  }

  health_checks = [var.health_check_id]

  depends_on = [google_compute_security_policy.foundry]
}

# --- Reserve static IP for load balancer ---
resource "google_compute_address" "foundry_lb" {
  name         = "${var.project_name}-foundry-ip"
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
  ip_version   = "IPV4"
}
