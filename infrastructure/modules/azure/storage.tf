# =============================================================================
# Azure Storage — Managed Disks, Snapshots, Backups
# =============================================================================

# ===== Data Disk for Foundry Persistent Storage =====
resource "azurerm_managed_disk" "foundry_data" {
  count                = var.compute_enabled ? 1 : 0
  name                 = "${local.name_prefix}-data-disk"
  location             = var.azure_region
  resource_group_name  = var.resource_group_name
  storage_account_type = var.data_disk_type
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size_gb
  encryption_settings {
    enabled = true
  }

  tags = local.common_tags
}

# ===== Disk Attachment =====
resource "azurerm_virtual_machine_data_disk_attachment" "foundry_data" {
  count              = var.compute_enabled ? 1 : 0
  managed_disk_id    = azurerm_managed_disk.foundry_data[0].id
  virtual_machine_id = azurerm_windows_virtual_machine.foundry[0].id
  lun                = 0
  caching            = "ReadWrite"
}

# ===== Backup Vault =====
resource "azurerm_backup_policy_vm" "daily" {
  name                = "${local.name_prefix}-daily-backup"
  resource_group_name = var.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.foundry[0].name

  backup {
    frequency = "Daily"
    time      = "02:00"
  }

  retention_daily {
    count = 30
  }

  retention_weekly {
    count    = 12
    weekdays = ["Sunday"]
  }

  retention_monthly {
    count    = 12
    weekdays = ["Sunday"]
    week     = "First"
  }

  depends_on = [azurerm_recovery_services_vault.foundry]
}

# ===== Recovery Services Vault =====
resource "azurerm_recovery_services_vault" "foundry" {
  count               = var.enable_monitoring ? 1 : 0
  name                = "${local.name_prefix}-backup-vault"
  location            = var.azure_region
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  soft_delete_enabled = true

  tags = local.common_tags
}

# ===== VM Backup Association =====
resource "azurerm_backup_protected_vm" "foundry" {
  count               = var.enable_monitoring && var.compute_enabled ? 1 : 0
  resource_group_name = var.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.foundry[0].name
  source_vm_id        = azurerm_windows_virtual_machine.foundry[0].id
  backup_policy_id    = azurerm_backup_policy_vm.daily.id

  depends_on = [azurerm_backup_policy_vm.daily]
}

# ===== Managed Disk Snapshot (Manual) =====
resource "azurerm_snapshot" "foundry_data_manual" {
  count                = var.compute_enabled ? 1 : 0
  name                 = "${local.name_prefix}-data-disk-snapshot"
  location             = var.azure_region
  resource_group_name  = var.resource_group_name
  create_option        = "Copy"
  source_resource_id   = azurerm_managed_disk.foundry_data[0].id
  storage_account_type = "Premium_LRS"

  tags = merge(local.common_tags, {
    SnapshotType = "Manual"
  })
}
