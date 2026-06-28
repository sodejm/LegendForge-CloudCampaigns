output "foundry_data_bucket" {
  description = "Foundry data bucket name"
  value       = google_storage_bucket.foundry_data.name
}

output "foundry_media_bucket" {
  description = "Foundry media bucket name"
  value       = google_storage_bucket.foundry_media.name
}

output "foundry_backups_bucket" {
  description = "Foundry backups bucket name"
  value       = google_storage_bucket.foundry_backups.name
}

output "foundry_logs_bucket" {
  description = "Foundry logs bucket name"
  value       = google_storage_bucket.foundry_logs.name
}

output "foundry_data_bucket_url" {
  description = "Foundry data bucket URL"
  value       = "gs://${google_storage_bucket.foundry_data.name}"
}

output "foundry_backups_bucket_url" {
  description = "Foundry backups bucket URL"
  value       = "gs://${google_storage_bucket.foundry_backups.name}"
}
