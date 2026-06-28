# =============================================================================
# Hetzner Deployment Outputs
# =============================================================================

output "server_public_ipv4" {
  description = "Server public IPv4"
  value       = module.foundry_hetzner.server_public_ipv4
}

output "server_private_ip" {
  description = "Server private IP"
  value       = module.foundry_hetzner.server_private_ip
}

output "server_summary" {
  description = "Server summary"
  value       = module.foundry_hetzner.server_summary
}

output "ssh_command" {
  description = "SSH command to connect"
  value       = var.compute_enabled ? "ssh root@${module.foundry_hetzner.server_public_ipv4}" : null
}

output "next_steps" {
  description = "Next steps"
  value = var.compute_enabled ? (
    <<-EOT
      1. Connect to server:
         ${module.foundry_hetzner.server_public_ipv4}

      2. Monitor container startup:
         ssh root@${module.foundry_hetzner.server_public_ipv4}
         docker logs -f foundry

      3. Access Foundry:
         https://${var.foundry_hostname}

      4. Complete setup at /setup with admin key
    EOT
  ) : "Instance is disabled"
}
