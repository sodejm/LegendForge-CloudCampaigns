output "vpc_id" {
  description = "VPC network ID"
  value       = google_compute_network.foundry_vpc.id
}

output "vpc_name" {
  description = "VPC network name"
  value       = google_compute_network.foundry_vpc.name
}

output "primary_subnet_id" {
  description = "Primary subnet ID"
  value       = google_compute_subnetwork.foundry_primary.id
}

output "primary_subnet_name" {
  description = "Primary subnet name"
  value       = google_compute_subnetwork.foundry_primary.name
}

output "secondary_subnet_id" {
  description = "Secondary subnet ID (if enabled)"
  value       = try(google_compute_subnetwork.foundry_secondary[0].id, null)
}

output "secondary_subnet_name" {
  description = "Secondary subnet name (if enabled)"
  value       = try(google_compute_subnetwork.foundry_secondary[0].name, null)
}

output "primary_region" {
  description = "Primary region"
  value       = var.primary_region
}

output "secondary_region" {
  description = "Secondary region"
  value       = var.secondary_region
}

output "router_id" {
  description = "Cloud Router ID"
  value       = google_compute_router.foundry_router.id
}

output "nat_ip" {
  description = "Cloud NAT static IPs (will show once allocated)"
  value       = google_compute_router_nat.foundry_nat.nat_ips
}
