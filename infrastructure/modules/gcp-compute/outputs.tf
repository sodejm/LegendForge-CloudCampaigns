output "instance_group_name" {
  description = "Instance Group Manager name"
  value       = google_compute_region_instance_group_manager.foundry.name
}

output "instance_group_id" {
  description = "Instance Group Manager ID"
  value       = google_compute_region_instance_group_manager.foundry.id
}

output "instance_template_id" {
  description = "Instance template ID"
  value       = google_compute_instance_template.foundry.id
}

output "health_check_id" {
  description = "Health check ID"
  value       = google_compute_health_check.foundry_http.id
}

output "health_check_self_link" {
  description = "Health check self link"
  value       = google_compute_health_check.foundry_http.self_link
}

output "target_pool_id" {
  description = "Note: Use Instance Group directly, not target pool"
  value       = "See instance_group_id"
}
