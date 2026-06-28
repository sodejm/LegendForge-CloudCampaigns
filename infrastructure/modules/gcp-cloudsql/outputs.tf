output "database_instance_name" {
  description = "Cloud SQL instance name"
  value       = google_sql_database_instance.foundry_primary.name
}

output "database_connection_name" {
  description = "Cloud SQL connection name (for Cloud SQL Proxy)"
  value       = google_sql_database_instance.foundry_primary.connection_name
}

output "database_private_ip" {
  description = "Private IP address of the Cloud SQL instance"
  value       = google_sql_database_instance.foundry_primary.private_ip_address
}

output "database_public_ip" {
  description = "Public IP address of the Cloud SQL instance (if enabled)"
  value       = try(google_sql_database_instance.foundry_primary.public_ip_address, null)
}

output "database_name" {
  description = "Foundry database name"
  value       = google_sql_database.foundry.name
}

output "database_user" {
  description = "Foundry application database user"
  value       = google_sql_user.foundry_app.name
  sensitive   = true
}

output "database_user_password" {
  description = "Foundry application database password (store in Secret Manager)"
  value       = random_password.db_user_password.result
  sensitive   = true
}

output "backup_user" {
  description = "Backup and monitoring database user"
  value       = google_sql_user.foundry_backup.name
}

output "backup_user_password" {
  description = "Backup user password (store in Secret Manager)"
  value       = random_password.db_backup_user_password.result
  sensitive   = true
}

output "ssl_cert" {
  description = "SSL certificate for encrypted connections"
  value       = google_sql_ssl_cert.foundry_ssl.cert
  sensitive   = true
}

output "ssl_cert_serial_number" {
  description = "SSL certificate serial number"
  value       = google_sql_ssl_cert.foundry_ssl.cert_serial_number
}

output "replica_instance_name" {
  description = "Read replica instance name (if enabled)"
  value       = try(google_sql_database_instance.foundry_replica[0].name, null)
}
