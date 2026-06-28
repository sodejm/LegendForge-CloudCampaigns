# =============================================================================
# Azure Module Outputs
# =============================================================================

output "vm_id" {
  description = "Azure VM resource ID"
  value       = var.compute_enabled ? azurerm_linux_virtual_machine.foundry[0].id : null
}

output "vm_name" {
  description = "Azure VM name"
  value       = var.compute_enabled ? azurerm_linux_virtual_machine.foundry[0].name : null
}

output "vm_public_ip" {
  description = "Public IP address of the VM"
  value       = var.compute_enabled ? azurerm_public_ip.vm[0].ip_address : null
}

output "vm_private_ip" {
  description = "Private IP address of the VM"
  value       = var.compute_enabled ? azurerm_network_interface.compute[0].private_ip_address : null
}

output "vnet_id" {
  description = "Virtual Network ID"
  value       = azurerm_virtual_network.main.id
}

output "subnet_id" {
  description = "Subnet ID"
  value       = azurerm_subnet.compute.id
}

output "nsg_id" {
  description = "Network Security Group ID"
  value       = azurerm_network_security_group.compute.id
}

output "nsg_name" {
  description = "Network Security Group name"
  value       = azurerm_network_security_group.compute.name
}

output "managed_identity_id" {
  description = "Managed Identity resource ID"
  value       = var.compute_enabled ? azurerm_user_assigned_identity.vm[0].id : null
}

output "managed_identity_principal_id" {
  description = "Managed Identity principal ID (for RBAC)"
  value       = var.compute_enabled ? azurerm_user_assigned_identity.vm[0].principal_id : null
}

output "key_vault_id" {
  description = "Key Vault resource ID"
  value       = azurerm_key_vault.foundry.id
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.foundry.vault_uri
}

output "data_disk_id" {
  description = "Managed Disk ID for Foundry data"
  value       = var.compute_enabled ? azurerm_managed_disk.foundry_data[0].id : null
}

output "recovery_vault_id" {
  description = "Recovery Services Vault ID"
  value       = var.enable_monitoring ? azurerm_recovery_services_vault.foundry[0].id : null
}

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  value       = var.enable_monitoring ? azurerm_log_analytics_workspace.main[0].id : null
}

output "bastion_public_ip" {
  description = "Azure Bastion public IP (if enabled)"
  value       = var.enable_bastion ? azurerm_public_ip.bastion[0].ip_address : null
}

output "vm_summary" {
  description = "Summary of VM details"
  value = var.compute_enabled ? {
    vm_id         = azurerm_linux_virtual_machine.foundry[0].id
    vm_name       = azurerm_linux_virtual_machine.foundry[0].name
    public_ip     = azurerm_public_ip.vm[0].ip_address
    private_ip    = azurerm_network_interface.compute[0].private_ip_address
    admin_username = var.admin_username
    vnet_id       = azurerm_virtual_network.main.id
    nsg_name      = azurerm_network_security_group.compute.name
    data_disk_size_gb = var.data_disk_size_gb
  } : null
}
