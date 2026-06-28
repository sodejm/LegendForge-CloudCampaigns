output "storage_account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.main.id
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "storage_account_primary_blob_endpoint" {
  description = "Primary blob endpoint"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "storage_account_primary_access_key" {
  description = "Primary access key"
  value       = azurerm_storage_account.main.primary_access_key
  sensitive   = true
}

output "storage_account_connection_string" {
  description = "Storage account connection string"
  value       = azurerm_storage_account.main.primary_blob_connection_string
  sensitive   = true
}

output "cdn_endpoint_url" {
  description = "CDN endpoint URL for media"
  value       = var.enable_cdn ? azurerm_cdn_endpoint.media[0].fqdn : null
}

output "foundry_data_container_url" {
  description = "URL to foundry-data container"
  value       = "${azurerm_storage_account.main.primary_blob_endpoint}${azurerm_storage_container.foundry_data.name}"
}
