output "load_balancer_ip" {
  description = "Static IP of the load balancer"
  value       = google_compute_address.foundry_lb.address
}

output "backend_service_id" {
  description = "Backend service ID"
  value       = google_compute_backend_service.foundry.id
}

output "https_proxy_id" {
  description = "HTTPS proxy ID"
  value       = google_compute_target_https_proxy.foundry.id
}

output "security_policy_id" {
  description = "Cloud Armor security policy ID"
  value       = google_compute_security_policy.foundry.id
}

output "ssl_certificate_domain" {
  description = "SSL certificate domain"
  value       = google_compute_managed_ssl_certificate.foundry.managed[0].domains
}

output "url_map_id" {
  description = "URL map ID"
  value       = google_compute_url_map.foundry.id
}
