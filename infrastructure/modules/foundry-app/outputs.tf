# =============================================================================
# modules/foundry-app/outputs.tf
# =============================================================================

output "user_data" {
  description = "Base64-encoded cloud-init user-data for Foundry provisioning"
  value       = base64encode(local.cloud_init_template)
  sensitive   = true
}

output "user_data_raw" {
  description = "Unencoded cloud-init user-data (for debugging)"
  value       = local.cloud_init_template
  sensitive   = true
}
