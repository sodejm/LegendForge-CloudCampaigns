output "resource_group_name" {
  description = "Azure resource group name"
  value       = module.networking.resource_group_name
}

output "load_balancer_public_ip" {
  description = "Public IP address of load balancer"
  value       = module.compute.load_balancer_frontend_ip_address
}

output "foundry_url" {
  description = "Access URL for D&D Foundry"
  value       = "http://${module.compute.load_balancer_frontend_ip_address}"
}

output "storage_account_name" {
  description = "Azure storage account name"
  value       = module.storage.storage_account_name
}

output "database_server_fqdn" {
  description = "Database server FQDN"
  value       = module.database.mysql_server_fqdn
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = module.security.key_vault_name
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = module.security.key_vault_uri
}

output "log_analytics_workspace_name" {
  description = "Log Analytics workspace name"
  value       = var.enable_monitoring ? module.monitoring[0].log_analytics_workspace_name : null
}

output "application_insights_name" {
  description = "Application Insights name"
  value       = var.enable_monitoring ? module.monitoring[0].application_insights_id : null
}

output "nat_gateway_public_ip" {
  description = "NAT Gateway public IP for whitelisting"
  value       = module.networking.nat_public_ip
}

output "vnet_id" {
  description = "Virtual network ID"
  value       = module.networking.vnet_id
}

output "scale_set_name" {
  description = "VM scale set name"
  value       = module.compute.scale_set_name
}

output "cdn_endpoint_url" {
  description = "CDN endpoint URL"
  value       = var.enable_cdn ? module.storage.cdn_endpoint_url : null
}

output "deployment_status" {
  description = "Deployment status"
  value       = "Successfully deployed D&D Foundry VTT on Azure"
}
