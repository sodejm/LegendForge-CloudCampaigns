mock_provider "google" {}

run "http_frontend_is_redirect_only" {
  command = apply

  module {
    source = "../../modules/gcp-loadbalancer"
  }

  variables {
    project_name      = "legendforge-fixture"
    domain_name       = "foundry.example.test"
    instance_group_id = "projects/fixture/zones/us-central1-a/instanceGroups/foundry"
    health_check_id   = "projects/fixture/global/healthChecks/foundry"
  }

  assert {
    condition     = google_compute_target_http_proxy.foundry_redirect.url_map != google_compute_target_https_proxy.foundry.url_map
    error_message = "HTTP must use a separate redirect-only URL map rather than serving the HTTPS application backend."
  }

  assert {
    condition = (
      google_compute_target_http_proxy.foundry_redirect.url_map == google_compute_url_map.foundry_http_redirect.id &&
      google_compute_url_map.foundry_http_redirect.default_service == null &&
      length(google_compute_url_map.foundry_http_redirect.host_rule) == 0 &&
      length(google_compute_url_map.foundry_http_redirect.path_matcher) == 0
    )
    error_message = "HTTP must have no route to an application backend."
  }

  assert {
    condition = (
      google_compute_url_map.foundry_http_redirect.default_url_redirect[0].https_redirect &&
      google_compute_url_map.foundry_http_redirect.default_url_redirect[0].redirect_response_code == "MOVED_PERMANENTLY_DEFAULT" &&
      !google_compute_url_map.foundry_http_redirect.default_url_redirect[0].strip_query &&
      google_compute_url_map.foundry_http_redirect.default_url_redirect[0].host_redirect == null &&
      google_compute_url_map.foundry_http_redirect.default_url_redirect[0].path_redirect == null &&
      google_compute_url_map.foundry_http_redirect.default_url_redirect[0].prefix_redirect == null
    )
    error_message = "HTTP must redirect to HTTPS with status 301, preserving the original host, path, and query."
  }

  assert {
    condition = (
      google_compute_global_forwarding_rule.foundry_http.target == google_compute_target_http_proxy.foundry_redirect.id &&
      google_compute_global_forwarding_rule.foundry_http.port_range == "80" &&
      google_compute_global_forwarding_rule.foundry_https.target == google_compute_target_https_proxy.foundry.id &&
      google_compute_global_forwarding_rule.foundry_https.port_range == "443" &&
      google_compute_global_forwarding_rule.foundry_http.ip_address == google_compute_global_address.foundry_lb.address &&
      google_compute_global_forwarding_rule.foundry_https.ip_address == google_compute_global_address.foundry_lb.address &&
      output.load_balancer_ip == google_compute_global_address.foundry_lb.address
    )
    error_message = "Both frontends and the DNS output must use the same global address and their respective proxies."
  }

  assert {
    condition = (
      google_compute_target_https_proxy.foundry.url_map == google_compute_url_map.foundry.id &&
      google_compute_url_map.foundry.default_service == google_compute_backend_service.foundry.id &&
      google_compute_url_map.foundry.path_matcher[0].default_service == google_compute_backend_service.foundry.id &&
      alltrue([for rule in google_compute_url_map.foundry.path_matcher[0].path_rule : rule.service == google_compute_backend_service.foundry.id])
    )
    error_message = "HTTPS application, asset, and WebSocket routes must continue to reach the existing Foundry backend."
  }
}
