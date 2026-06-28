# =============================================================================
# infrastructure/modules/azure/database/main.tf
# =============================================================================
# LegendForge Database module configuration for universal tabletop infrastructure supporting multiple game systems.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# =============================================================================

# MySQL Flexible Server
resource "azurerm_mysql_flexible_server" "main" {
  count               = var.db_engine == "mysql" ? 1 : 0
  name                = "mysql-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  administrator_login = var.admin_username
  administrator_password = var.admin_password

  sku_name                     = var.db_sku_name
  version                      = var.db_version
  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled
  zone                         = "1"
  high_availability {
    mode = var.high_availability_enabled ? "ZoneRedundant" : "SameZone"
  }

  delegated_subnet_id = var.database_subnet_id
  private_dns_zone_id = azurerm_private_dns_zone.mysql[0].id

  storage {
    iops    = 360
    size_gb = var.db_storage_size
  }

  maintenance_window {
    day_of_week  = 0
    start_hour   = 2
    start_minute = 0
  }

  tags = var.tags

  depends_on = [azurerm_private_dns_zone_virtual_network_link.mysql]
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "main" {
  count               = var.db_engine == "postgres" ? 1 : 0
  name                = "postgres-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  administrator_login = var.admin_username
  administrator_password = var.admin_password

  sku_name                     = var.db_sku_name
  version                      = var.db_version
  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled
  zone                         = "1"

  high_availability {
    mode = var.high_availability_enabled ? "ZoneRedundant" : "SameZone"
  }

  delegated_subnet_id = var.database_subnet_id
  private_dns_zone_id = azurerm_private_dns_zone.postgres[0].id

  storage_mb = var.db_storage_size * 1024

  maintenance_window {
    day_of_week  = 0
    start_hour   = 2
    start_minute = 0
  }

  tags = var.tags

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
}

# MySQL Database
resource "azurerm_mysql_flexible_database" "foundry" {
  count               = var.db_engine == "mysql" ? 1 : 0
  name                = "${replace(var.project_name, "-", "_")}_db"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.main[0].name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

# PostgreSQL Database
resource "azurerm_postgresql_flexible_server_database" "foundry" {
  count               = var.db_engine == "postgres" ? 1 : 0
  name                = replace(var.project_name, "-", "_")
  server_id           = azurerm_postgresql_flexible_server.main[0].id
  collation           = "en_US.utf8"
  charset             = "UTF8"
}

# MySQL Firewall Rule (allow from app subnet)
resource "azurerm_mysql_flexible_server_firewall_rule" "app" {
  count               = var.db_engine == "mysql" ? 1 : 0
  name                = "AllowAppSubnet"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.main[0].name
  start_ip_address    = "10.0.2.0"
  end_ip_address      = "10.0.3.255"
}

# PostgreSQL Firewall Rule (allow from app subnet)
resource "azurerm_postgresql_flexible_server_firewall_rule" "app" {
  count               = var.db_engine == "postgres" ? 1 : 0
  name                = "AllowAppSubnet"
  server_name         = azurerm_postgresql_flexible_server.main[0].name
  resource_group_name = var.resource_group_name
  start_ip_address    = "10.0.2.0"
  end_ip_address      = "10.0.3.255"
}

# Private DNS Zones
resource "azurerm_private_dns_zone" "mysql" {
  count               = var.db_engine == "mysql" ? 1 : 0
  name                = "mysql.database.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "postgres" {
  count               = var.db_engine == "postgres" ? 1 : 0
  name                = "postgres.database.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Link Private DNS Zones to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "mysql" {
  count                 = var.db_engine == "mysql" ? 1 : 0
  name                  = "link-${var.environment}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.mysql[0].name
  virtual_network_id    = var.vnet_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  count                 = var.db_engine == "postgres" ? 1 : 0
  name                  = "link-${var.environment}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.postgres[0].name
  virtual_network_id    = var.vnet_id
}

# MySQL Configuration
resource "azurerm_mysql_flexible_server_configuration" "innodb_buffer_pool" {
  count               = var.db_engine == "mysql" ? 1 : 0
  name                = "innodb_buffer_pool_size"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.main[0].name
  value               = "805306368" # 768MB
}

resource "azurerm_mysql_flexible_server_configuration" "max_connections" {
  count               = var.db_engine == "mysql" ? 1 : 0
  name                = "max_connections"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.main[0].name
  value               = "500"
}

# PostgreSQL Configuration
resource "azurerm_postgresql_flexible_server_configuration" "max_connections" {
  count               = var.db_engine == "postgres" ? 1 : 0
  name                = "max_connections"
  server_name         = azurerm_postgresql_flexible_server.main[0].name
  resource_group_name = var.resource_group_name
  value               = "500"
}
