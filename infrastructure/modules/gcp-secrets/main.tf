# =============================================================================
# infrastructure/modules/gcp-secrets/main.tf
# =============================================================================
# LegendForge GCP Secrets module configuration for universal tabletop infrastructure supporting multiple game systems.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# =============================================================================

# --- Database Credentials ---
resource "google_secret_manager_secret" "db_password" {
  secret_id = "${var.project_name}-db-password"

  replication {
    auto {}
  }

  labels = var.labels
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = var.database_password
}

# --- Foundry License Key ---
resource "google_secret_manager_secret" "foundry_license" {
  secret_id = "${var.project_name}-foundry-license-key"

  replication {
    auto {}
  }

  labels = var.labels
}

resource "google_secret_manager_secret_version" "foundry_license" {
  secret      = google_secret_manager_secret.foundry_license.id
  secret_data = var.foundry_license_key
}

# --- Foundry Admin Key ---
resource "google_secret_manager_secret" "foundry_admin_key" {
  secret_id = "${var.project_name}-foundry-admin-key"

  replication {
    auto {}
  }

  labels = var.labels
}

resource "google_secret_manager_secret_version" "foundry_admin_key" {
  secret      = google_secret_manager_secret.foundry_admin_key.id
  secret_data = var.foundry_admin_key
}

# --- Foundry Username (for downloads) ---
resource "google_secret_manager_secret" "foundry_username" {
  secret_id = "${var.project_name}-foundry-username"

  replication {
    auto {}
  }

  labels = var.labels
}

resource "google_secret_manager_secret_version" "foundry_username" {
  secret      = google_secret_manager_secret.foundry_username.id
  secret_data = var.foundry_username
}

# --- Foundry Password (for downloads) ---
resource "google_secret_manager_secret" "foundry_password" {
  secret_id = "${var.project_name}-foundry-password"

  replication {
    auto {}
  }

  labels = var.labels
}

resource "google_secret_manager_secret_version" "foundry_password" {
  secret      = google_secret_manager_secret.foundry_password.id
  secret_data = var.foundry_password
}

# --- Cloudflare Tunnel Token ---
resource "google_secret_manager_secret" "cloudflare_token" {
  secret_id = "${var.project_name}-cloudflare-tunnel-token"

  replication {
    auto {}
  }

  labels = var.labels
}

resource "google_secret_manager_secret_version" "cloudflare_token" {
  secret      = google_secret_manager_secret.cloudflare_token.id
  secret_data = var.cloudflare_tunnel_token
}

# --- IAM Binding: Allow Foundry compute SA to access secrets ---
resource "google_secret_manager_secret_iam_member" "compute_db_password" {
  secret_id = google_secret_manager_secret.db_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.foundry_compute_sa_email}"
}

resource "google_secret_manager_secret_iam_member" "compute_foundry_license" {
  secret_id = google_secret_manager_secret.foundry_license.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.foundry_compute_sa_email}"
}

resource "google_secret_manager_secret_iam_member" "compute_foundry_admin_key" {
  secret_id = google_secret_manager_secret.foundry_admin_key.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.foundry_compute_sa_email}"
}

resource "google_secret_manager_secret_iam_member" "compute_foundry_username" {
  secret_id = google_secret_manager_secret.foundry_username.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.foundry_compute_sa_email}"
}

resource "google_secret_manager_secret_iam_member" "compute_foundry_password" {
  secret_id = google_secret_manager_secret.foundry_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.foundry_compute_sa_email}"
}

resource "google_secret_manager_secret_iam_member" "compute_cloudflare_token" {
  secret_id = google_secret_manager_secret.cloudflare_token.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.foundry_compute_sa_email}"
}

# --- KMS Key for Secret Encryption (optional, but recommended) ---
resource "google_kms_key_ring" "foundry_secrets" {
  name     = "${var.project_name}-secrets-keyring"
  location = var.region
}

resource "google_kms_crypto_key" "foundry_secrets" {
  name            = "${var.project_name}-secrets-key"
  key_ring        = google_kms_key_ring.foundry_secrets.id
  rotation_period = "7776000s" # 90 days

  lifecycle {
    prevent_destroy = true
  }
}

# --- KMS IAM: Allow Secret Manager to use KMS key ---
resource "google_kms_crypto_key_iam_member" "secret_manager" {
  crypto_key_id = google_kms_crypto_key.foundry_secrets.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${var.gcp_project_number}@gcp-sa-secretmanager.iam.gserviceaccount.com"
}
