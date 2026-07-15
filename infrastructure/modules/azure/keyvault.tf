# =============================================================================
# Azure Key Vault — Secrets Management
# =============================================================================

# ===== Key Vault =====
resource "azurerm_key_vault" "foundry" {
  name                = "${replace(local.name_prefix, "-", "")}kv" # No hyphens allowed
  location            = var.azure_region
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Networking
  network_acls {
    bypass                     = "AzureServices"
    default_action             = "Deny"
    virtual_network_subnet_ids = [azurerm_subnet.compute.id]
  }

  # Disable access policies in favor of RBAC
  enable_rbac_authorization = true

  # Purge protection for disaster recovery
  purge_protection_enabled = false

  # Vault access
  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true

  tags = local.common_tags
}

# ===== Key Vault Secrets =====
resource "azurerm_key_vault_secret" "foundry_license_key" {
  name            = "foundry-license-key"
  value           = var.foundry_license_key
  key_vault_id    = azurerm_key_vault.foundry.id
  content_type    = "password"
  expiration_date = timeadd(timestamp(), "8760h") # 1 year from now

  tags = local.common_tags
}

resource "azurerm_key_vault_secret" "foundry_admin_key" {
  name         = "foundry-admin-key"
  value        = var.foundry_admin_key
  key_vault_id = azurerm_key_vault.foundry.id
  content_type = "password"

  tags = local.common_tags
}

resource "azurerm_key_vault_secret" "cloudflare_tunnel_token" {
  name         = "cloudflare-tunnel-token"
  value        = var.cloudflare_tunnel_token
  key_vault_id = azurerm_key_vault.foundry.id
  content_type = "password"

  tags = local.common_tags
}

# Store Foundry download credentials (optional, if using username/password)
resource "azurerm_key_vault_secret" "foundry_username" {
  count        = var.foundry_username != "" ? 1 : 0
  name         = "foundry-username"
  value        = var.foundry_username
  key_vault_id = azurerm_key_vault.foundry.id
  content_type = "text/plain"

  tags = local.common_tags
}

resource "azurerm_key_vault_secret" "foundry_password" {
  count        = var.foundry_password != "" ? 1 : 0
  name         = "foundry-password"
  value        = var.foundry_password
  key_vault_id = azurerm_key_vault.foundry.id
  content_type = "password"

  tags = local.common_tags
}

resource "azurerm_key_vault_secret" "foundry_release_url" {
  count           = var.foundry_release_url != "" ? 1 : 0
  name            = "foundry-release-url"
  value           = var.foundry_release_url
  key_vault_id    = azurerm_key_vault.foundry.id
  content_type    = "password"
  expiration_date = timeadd(timestamp(), "24h") # Timed URLs expire quickly

  tags = local.common_tags
}

# ===== RBAC: Managed Identity Access to Key Vault =====
resource "azurerm_role_assignment" "vm_keyvault_secrets_read" {
  scope                = azurerm_key_vault.foundry.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.vm[0].principal_id

  depends_on = [azurerm_user_assigned_identity.vm]
}

# ===== Data source: Current Azure Client Config =====
data "azurerm_client_config" "current" {}
