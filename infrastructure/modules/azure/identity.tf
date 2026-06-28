# =============================================================================
# Azure Identity — Managed Identities, Role Assignments
# =============================================================================

# ===== User Assigned Managed Identity for VM =====
resource "azurerm_user_assigned_identity" "vm" {
  count               = var.compute_enabled ? 1 : 0
  resource_group_name = var.resource_group_name
  location            = var.azure_region
  name                = "${local.name_prefix}-identity"

  tags = local.common_tags
}

# ===== RBAC Role Assignment: VM → Key Vault Secrets User =====
# (Already defined in keyvault.tf, but can be managed here)

# ===== RBAC Role Assignment: VM → Key Vault Certificate Officer (future) =====
resource "azurerm_role_assignment" "vm_keyvault_certs" {
  count              = var.compute_enabled ? 1 : 0
  scope              = azurerm_key_vault.foundry.id
  role_definition_name = "Key Vault Certificate Officer"
  principal_id       = azurerm_user_assigned_identity.vm[0].principal_id

  depends_on = [azurerm_user_assigned_identity.vm, azurerm_key_vault.foundry]
}

# ===== RBAC Role Assignment: VM → Monitoring Metrics Publisher =====
resource "azurerm_role_assignment" "vm_monitor_metrics" {
  count              = var.compute_enabled && var.enable_monitoring ? 1 : 0
  scope              = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id       = azurerm_user_assigned_identity.vm[0].principal_id

  depends_on = [azurerm_user_assigned_identity.vm]
}

# ===== RBAC Role Assignment: VM → Log Analytics Contributor =====
resource "azurerm_role_assignment" "vm_log_analytics" {
  count              = var.compute_enabled && var.enable_monitoring ? 1 : 0
  scope              = azurerm_log_analytics_workspace.main[0].id
  role_definition_name = "Log Analytics Contributor"
  principal_id       = azurerm_user_assigned_identity.vm[0].principal_id

  depends_on = [azurerm_user_assigned_identity.vm, azurerm_log_analytics_workspace.main]
}
