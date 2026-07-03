# =============================================================================
# Azure Compute — Virtual Machine, OS Disk, User Data
# =============================================================================

# ===== Virtual Machine =====
resource "azurerm_linux_virtual_machine" "foundry" {
  count               = var.compute_enabled ? 1 : 0
  name                = "${local.name_prefix}-vm"
  location            = var.azure_region
  resource_group_name = var.resource_group_name
  vm_size             = var.vm_size

  # Disable password authentication, use SSH keys only
  disable_password_authentication = true

  admin_username = var.admin_username

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  # OS Disk Configuration
  os_disk {
    caching                = "ReadWrite"
    storage_account_type   = "Premium_LRS"
    disk_size_gb           = local.os_disk_size_gb
    disk_encryption_set_id = var.enable_monitoring ? azurerm_disk_encryption_set.vm[0].id : null
  }

  # Source Image Reference: Ubuntu 22.04 LTS
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Network Interface
  network_interface_ids = [
    azurerm_network_interface.compute[0].id,
  ]

  # Identity: Managed Identity for Key Vault access
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.vm[0].id]
  }

  # User Data: Cloud-Init script
  custom_data = base64encode(module.foundry_app.user_data)

  # OS Profile: Linux-specific settings
  os_profile_linux_config {
    disable_password_authentication = true
  }

  # Encryption
  encryption_at_host_enabled = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vm"
  })

  depends_on = [
    azurerm_key_vault.foundry,
    azurerm_network_interface.compute
  ]
}

# ===== Foundry App Module (Provider-agnostic cloud-init generator) =====
module "foundry_app" {
  source = "../../modules/foundry-app"

  foundry_hostname        = var.foundry_hostname
  data_device             = "/dev/disk/by-id/scsi-*-lun-0" # Azure managed disk pattern
  data_mount_path         = var.data_mount_path
  data_volume_fs_label    = var.data_volume_fs_label
  foundry_image           = var.foundry_image
  cloudflared_image       = var.cloudflared_image
  timezone                = var.timezone
  foundry_username        = var.foundry_username
  foundry_password        = var.foundry_password
  foundry_release_url     = var.foundry_release_url
  foundry_license_key     = var.foundry_license_key
  foundry_admin_key       = var.foundry_admin_key
  cloudflare_tunnel_token = var.cloudflare_tunnel_token
}

# ===== Disk Encryption Set (for CMK encryption) =====
resource "azurerm_disk_encryption_set" "vm" {
  count               = var.enable_monitoring ? 1 : 0
  name                = "${local.name_prefix}-des"
  location            = var.azure_region
  resource_group_name = var.resource_group_name
  key_vault_key_id    = azurerm_key_vault_key.vm[0].id

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags

  depends_on = [azurerm_key_vault.foundry]
}

# ===== Key Vault Key for Disk Encryption =====
resource "azurerm_key_vault_key" "vm" {
  count        = var.enable_monitoring ? 1 : 0
  name         = "${local.name_prefix}-disk-key"
  key_vault_id = azurerm_key_vault.foundry.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
}

# ===== Grant Disk Encryption Set access to Key Vault =====
resource "azurerm_key_vault_access_policy" "disk_encryption" {
  count        = var.enable_monitoring ? 1 : 0
  key_vault_id = azurerm_key_vault.foundry.id
  tenant_id    = azurerm_disk_encryption_set.vm[0].identity[0].tenant_id
  object_id    = azurerm_disk_encryption_set.vm[0].identity[0].principal_id

  key_permissions = [
    "Get",
    "WrapKey",
    "UnwrapKey",
  ]

  depends_on = [azurerm_disk_encryption_set.vm, azurerm_key_vault_key.vm]
}

# ===== Diagnostic Settings for VM =====
resource "azurerm_monitor_diagnostic_setting" "vm" {
  count                      = var.enable_monitoring ? 1 : 0
  name                       = "${local.name_prefix}-diag"
  target_resource_id         = azurerm_linux_virtual_machine.foundry[0].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main[0].id

  enabled_log {
    category = "Administrative"
  }

  enabled_log {
    category = "Operational"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }

  depends_on = [azurerm_log_analytics_workspace.main, azurerm_linux_virtual_machine.foundry]
}

# ===== Alerts =====
resource "azurerm_monitor_metric_alert" "vm_cpu_high" {
  count               = var.compute_enabled && var.enable_monitoring ? 1 : 0
  name                = "${local.name_prefix}-cpu-alert"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_linux_virtual_machine.foundry[0].id]

  description = "Alert when CPU exceeds 80%"
  severity    = 2

  criteria {
    metric_name      = "Percentage CPU"
    operator         = "GreaterThan"
    threshold        = 80
    aggregation      = "Average"
    metric_namespace = "Microsoft.Compute/virtualMachines"
  }

  window_size   = "PT5M"
  frequency     = "PT1M"
  auto_mitigate = true
}
