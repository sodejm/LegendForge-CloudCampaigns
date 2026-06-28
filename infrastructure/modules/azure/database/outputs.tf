output "mysql_server_id" {
  description = "ID of MySQL server"
  value       = try(azurerm_mysql_flexible_server.main[0].id, null)
}

output "mysql_server_fqdn" {
  description = "FQDN of MySQL server"
  value       = try(azurerm_mysql_flexible_server.main[0].fqdn, null)
}

output "postgres_server_id" {
  description = "ID of PostgreSQL server"
  value       = try(azurerm_postgresql_flexible_server.main[0].id, null)
}

output "postgres_server_fqdn" {
  description = "FQDN of PostgreSQL server"
  value       = try(azurerm_postgresql_flexible_server.main[0].fqdn, null)
}

output "database_name" {
  description = "Name of the Foundry database"
  value = var.db_engine == "mysql" ? (
    try(azurerm_mysql_flexible_database.foundry[0].name, null)
  ) : (
    try(azurerm_postgresql_flexible_server_database.foundry[0].name, null)
  )
}
