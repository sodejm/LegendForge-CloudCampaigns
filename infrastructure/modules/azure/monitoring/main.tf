# =============================================================================
# infrastructure/modules/azure/monitoring/main.tf
# =============================================================================
# LegendForge Monitoring module configuration for universal tabletop infrastructure supporting multiple game systems.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# =============================================================================

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days

  tags = var.tags
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = "ai-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.main.id
  retention_in_days   = var.log_retention_days

  tags = var.tags
}

# Diagnostic Settings for Scale Set
resource "azurerm_monitor_diagnostic_setting" "scale_set" {
  name                       = "diag-vmss"
  target_resource_id         = var.scale_set_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "Administrative"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Diagnostic Settings for Load Balancer
resource "azurerm_monitor_diagnostic_setting" "load_balancer" {
  name                       = "diag-lb"
  target_resource_id         = var.load_balancer_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "LoadBalancerAlertEvent"
  }

  enabled_log {
    category = "LoadBalancerProbeHealthStatus"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Diagnostic Settings for Storage
resource "azurerm_monitor_diagnostic_setting" "storage" {
  name                       = "diag-storage"
  target_resource_id         = "${var.storage_account_id}/blobServices/default"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  metric {
    category = "Transaction"
    enabled  = true
  }
}

# Diagnostic Settings for Database
resource "azurerm_monitor_diagnostic_setting" "database" {
  name                       = "diag-database"
  target_resource_id         = var.database_server_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "MySqlSlowLogs"
  }

  enabled_log {
    category = "MySqlAuditLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Diagnostic Settings for Key Vault
resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  name                       = "diag-keyvault"
  target_resource_id         = var.key_vault_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "AuditEvent"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Action Group for Alerts
resource "azurerm_monitor_action_group" "main" {
  name                = "ag-${var.project_name}-${var.environment}"
  resource_group_name = var.resource_group_name
  short_name          = "LegendForge"

  email_receiver {
    name           = "Send to admin"
    email_address  = var.metric_alert_email
    use_common_alert_schema = true
  }

  tags = var.tags
}

# Alert Rule - High CPU on Scale Set
resource "azurerm_monitor_metric_alert" "high_cpu" {
  name                = "alert-high-cpu"
  resource_group_name = var.resource_group_name
  scopes              = [var.scale_set_id]
  description         = "Alert when CPU exceeds 80%"
  severity            = 2
  enabled             = true
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
    metric_namespace = "Microsoft.Compute/virtualMachineScaleSets"
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}

# Alert Rule - Low Available Memory
resource "azurerm_monitor_metric_alert" "low_memory" {
  name                = "alert-low-memory"
  resource_group_name = var.resource_group_name
  scopes              = [var.scale_set_id]
  description         = "Alert when available memory is low"
  severity            = 2
  enabled             = true
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_name      = "Available Memory Bytes"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 536870912 # 512MB
    metric_namespace = "Microsoft.Compute/virtualMachineScaleSets"
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}

# Alert Rule - Database CPU
resource "azurerm_monitor_metric_alert" "database_cpu" {
  name                = "alert-database-cpu"
  resource_group_name = var.resource_group_name
  scopes              = [var.database_server_id]
  description         = "Alert when database CPU exceeds 85%"
  severity            = 2
  enabled             = true
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_name      = "cpu_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
    metric_namespace = "Microsoft.DBforMySQL/flexibleServers"
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}

# Alert Rule - Storage Quota
resource "azurerm_monitor_metric_alert" "storage_quota" {
  name                = "alert-storage-quota"
  resource_group_name = var.resource_group_name
  scopes              = [var.storage_account_id]
  description         = "Alert when storage usage exceeds 80%"
  severity            = 2
  enabled             = true
  frequency           = "PT1H"
  window_size         = "PT1H"

  criteria {
    metric_name      = "UsedCapacity"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80000000000 # 80GB
    metric_namespace = "Microsoft.Storage/storageAccounts/blobServices"
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}

# Dashboard
resource "azurerm_portal_dashboard" "main" {
  name                = "dashboard-${var.project_name}-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  dashboard_properties = jsonencode({
    lenses = {
      "0" = {
        order = 0
        parts = {
          "0" = {
            position = {
              x = 0
              y = 0
              colSpan = 6
              rowSpan = 4
            }
            metadata = {
              inputs = [
                {
                  name = "resourceGroup"
                  value = var.resource_group_name
                }
              ]
              type = "Extension/HubsExtension/PartType/ResourceGroupMapPinnedPart"
            }
          }
          "1" = {
            position = {
              x = 6
              y = 0
              colSpan = 6
              rowSpan = 4
            }
            metadata = {
              inputs = [
                {
                  name = "resourceId"
                  value = var.scale_set_id
                }
              ]
              type = "Extension/Microsoft_Azure_Monitoring/PartType/MetricsChartPart"
            }
          }
        }
      }
    }
  })
}
