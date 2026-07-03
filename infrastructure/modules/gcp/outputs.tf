# =============================================================================
# GCP Module Outputs
# =============================================================================

output "instance_id" {
  description = "Compute Engine instance ID"
  value       = var.compute_enabled ? google_compute_instance.foundry[0].id : null
}

output "instance_name" {
  description = "Compute Engine instance name"
  value       = var.compute_enabled ? google_compute_instance.foundry[0].name : null
}

output "instance_public_ip" {
  description = "Public IP of the instance (if assigned)"
  value = var.compute_enabled && length(google_compute_instance.foundry[0].network_interface) > 0 ? (
    length(google_compute_instance.foundry[0].network_interface[0].access_config) > 0 ?
    google_compute_instance.foundry[0].network_interface[0].access_config[0].nat_ip : null
  ) : null
}

output "instance_internal_ip" {
  description = "Internal IP of the instance"
  value       = var.compute_enabled ? google_compute_instance.foundry[0].network_interface[0].network_ip : null
}

output "vpc_network_name" {
  description = "VPC network name"
  value       = google_compute_network.foundry.name
}

output "vpc_network_id" {
  description = "VPC network ID"
  value       = google_compute_network.foundry.id
}

output "subnet_name" {
  description = "Subnet name"
  value       = google_compute_subnetwork.foundry.name
}

output "data_disk_id" {
  description = "Persistent disk ID for Foundry data"
  value       = var.compute_enabled ? google_compute_disk.foundry_data[0].id : null
}

output "service_account_email" {
  description = "Service account email"
  value       = google_service_account.foundry.email
}

output "service_account_id" {
  description = "Service account ID"
  value       = google_service_account.foundry.unique_id
}

output "instance_summary" {
  description = "Summary of GCP instance details"
  value = var.compute_enabled ? {
    instance_name   = google_compute_instance.foundry[0].name
    zone            = google_compute_instance.foundry[0].zone
    machine_type    = google_compute_instance.foundry[0].machine_type
    internal_ip     = google_compute_instance.foundry[0].network_interface[0].network_ip
    vpc_network     = google_compute_network.foundry.name
    service_account = google_service_account.foundry.email
  } : null
}
