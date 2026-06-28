# =============================================================================
# Hetzner Module Outputs
# =============================================================================

output "server_id" {
  description = "Hetzner server ID"
  value       = var.compute_enabled ? hcloud_server.foundry[0].id : null
}

output "server_name" {
  description = "Hetzner server name"
  value       = var.compute_enabled ? hcloud_server.foundry[0].name : null
}

output "server_public_ipv4" {
  description = "Server public IPv4 address"
  value       = var.compute_enabled ? hcloud_server.foundry[0].ipv4_address : null
}

output "server_public_ipv6" {
  description = "Server public IPv6 address"
  value       = var.compute_enabled ? hcloud_server.foundry[0].ipv6_address : null
}

output "server_private_ip" {
  description = "Server private IP (in VPC)"
  value       = var.compute_enabled ? hcloud_server_network.foundry[0].ip : null
}

output "network_id" {
  description = "Hetzner network ID"
  value       = hcloud_network.foundry.id
}

output "volume_id" {
  description = "Hetzner volume ID for Foundry data"
  value       = var.compute_enabled ? hcloud_volume.foundry_data[0].id : null
}

output "firewall_id" {
  description = "Hetzner firewall ID"
  value       = hcloud_firewall.foundry.id
}

output "server_summary" {
  description = "Summary of server details"
  value = var.compute_enabled ? {
    server_name = hcloud_server.foundry[0].name
    public_ipv4 = hcloud_server.foundry[0].ipv4_address
    datacenter  = hcloud_server.foundry[0].datacenter
    server_type = hcloud_server.foundry[0].server_type
    volume_size = hcloud_volume.foundry_data[0].size
  } : null
}
