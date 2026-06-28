output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.main.id
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "gateway_subnet_id" {
  description = "ID of the gateway subnet"
  value       = azurerm_subnet.gateway.id
}

output "app_subnet_id" {
  description = "ID of the app subnet"
  value       = azurerm_subnet.app.id
}

output "database_subnet_id" {
  description = "ID of the database subnet"
  value       = azurerm_subnet.database.id
}

output "storage_subnet_id" {
  description = "ID of the storage subnet"
  value       = azurerm_subnet.storage.id
}

output "nat_gateway_id" {
  description = "ID of the NAT gateway"
  value       = var.enable_nat_gateway ? azurerm_nat_gateway.main[0].id : null
}

output "nat_public_ip" {
  description = "Public IP of NAT gateway for whitelisting"
  value       = var.enable_nat_gateway ? azurerm_public_ip.nat[0].ip_address : null
}

output "gateway_nsg_id" {
  description = "ID of gateway NSG"
  value       = azurerm_network_security_group.gateway.id
}

output "app_nsg_id" {
  description = "ID of app NSG"
  value       = azurerm_network_security_group.app.id
}

output "database_nsg_id" {
  description = "ID of database NSG"
  value       = azurerm_network_security_group.database.id
}

output "storage_nsg_id" {
  description = "ID of storage NSG"
  value       = azurerm_network_security_group.storage.id
}
