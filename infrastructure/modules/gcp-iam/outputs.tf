output "foundry_compute_sa_email" {
  description = "Foundry compute service account email"
  value       = google_service_account.foundry_compute.email
}

output "foundry_compute_sa_name" {
  description = "Foundry compute service account name"
  value       = google_service_account.foundry_compute.account_id
}

output "foundry_cloudsql_sa_email" {
  description = "Cloud SQL service account email"
  value       = google_service_account.foundry_cloudsql.email
}

output "foundry_storage_sa_email" {
  description = "Storage service account email"
  value       = google_service_account.foundry_storage.email
}

output "foundry_monitoring_sa_email" {
  description = "Monitoring service account email"
  value       = google_service_account.foundry_monitoring.email
}

output "foundry_secrets_sa_email" {
  description = "Secrets service account email"
  value       = google_service_account.foundry_secrets.email
}

output "custom_compute_role_id" {
  description = "Custom Foundry compute role ID"
  value       = google_project_iam_custom_role.foundry_compute_role.id
}
