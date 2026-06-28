output "scale_set_id" {
  description = "ID of the VM Scale Set"
  value       = azurerm_linux_virtual_machine_scale_set.main.id
}

output "scale_set_name" {
  description = "Name of the VM Scale Set"
  value       = azurerm_linux_virtual_machine_scale_set.main.name
}

output "load_balancer_id" {
  description = "ID of the load balancer"
  value       = azurerm_lb.main.id
}

output "load_balancer_frontend_ip_address" {
  description = "Frontend IP address of load balancer"
  value       = azurerm_public_ip.lb.ip_address
}

output "managed_identity_id" {
  description = "ID of managed identity for VMs"
  value       = azurerm_user_assigned_identity.vmss.id
}

output "managed_identity_principal_id" {
  description = "Principal ID of managed identity for VMs"
  value       = azurerm_user_assigned_identity.vmss.principal_id
}
