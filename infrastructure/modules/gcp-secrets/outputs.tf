output "db_password_secret_id" {
  description = "Database password secret ID"
  value       = google_secret_manager_secret.db_password.id
}

output "foundry_license_secret_id" {
  description = "Foundry license secret ID"
  value       = google_secret_manager_secret.foundry_license.id
}

output "foundry_admin_key_secret_id" {
  description = "Foundry admin key secret ID"
  value       = google_secret_manager_secret.foundry_admin_key.id
}

output "foundry_username_secret_id" {
  description = "Foundry username secret ID"
  value       = google_secret_manager_secret.foundry_username.id
}

output "foundry_password_secret_id" {
  description = "Foundry password secret ID"
  value       = google_secret_manager_secret.foundry_password.id
}

output "cloudflare_token_secret_id" {
  description = "Cloudflare token secret ID"
  value       = google_secret_manager_secret.cloudflare_token.id
}

output "kms_key_id" {
  description = "KMS key ID for additional encryption"
  value       = google_kms_crypto_key.foundry_secrets.id
}

output "kms_keyring_id" {
  description = "KMS keyring ID"
  value       = google_kms_key_ring.foundry_secrets.id
}
