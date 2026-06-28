# =============================================================================
# infrastructure/modules/foundry-app/main.tf
# =============================================================================
# LegendForge application bootstrap configuration for Foundry-powered multi-system runtime provisioning.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# =============================================================================

# --- Generate the cloud-config document ---
locals {
  # Build the cloud-init script with all LegendForge configuration
  cloud_init_template = templatefile("${path.module}/templates/cloud-init.yaml", {
    foundry_hostname         = var.foundry_hostname
    data_mount_path          = var.data_mount_path
    data_device              = var.data_device
    data_volume_fs_label     = var.data_volume_fs_label
    foundry_image            = var.foundry_image
    cloudflared_image        = var.cloudflared_image
    timezone                 = var.timezone != "" ? var.timezone : "UTC"
    foundry_username         = var.foundry_username
    foundry_password         = var.foundry_password
    foundry_release_url      = var.foundry_release_url
    foundry_license_key      = var.foundry_license_key
    foundry_admin_key        = var.foundry_admin_key
    cloudflare_tunnel_token  = var.cloudflare_tunnel_token
  })
}

# =============================================================================
# Output: cloud-init user-data for VM provisioning
# =============================================================================
output "user_data" {
  description = "Cloud-init user-data script for LegendForge provisioning"
  value       = base64encode(local.cloud_init_template)
  sensitive   = true
}

output "user_data_raw" {
  description = "Cloud-init user-data script (unencoded)"
  value       = local.cloud_init_template
  sensitive   = true
}
