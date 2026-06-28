# =============================================================================
# modules/foundry-app/outputs.tf
# =============================================================================

output "user_data" {
  description = "Base64-encoded cloud-init user-data for Foundry provisioning"
  value       = base64encode(templatefile("${path.module}/templates/cloud-init.yaml", {
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
  }))
  sensitive = true
}

output "user_data_raw" {
  description = "Unencoded cloud-init user-data (for debugging)"
  value       = templatefile("${path.module}/templates/cloud-init.yaml", {
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
  sensitive = true
}
