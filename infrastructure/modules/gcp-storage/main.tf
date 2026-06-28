# =============================================================================
# infrastructure/modules/gcp-storage/main.tf
# =============================================================================
# LegendForge GCP Storage module configuration for universal tabletop infrastructure supporting multiple game systems.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# - Media Assets bucket (images, sounds, videos)
# - Backups bucket (database and config backups)
# All buckets are encrypted, versioned, and include lifecycle policies.
# =============================================================================

# --- Main Foundry Data Bucket (worlds, user data, modules) --- for LegendForge multi-system operations.
resource "google_storage_bucket" "foundry_data" {
  name          = "${var.project_name}-foundry-data-${data.google_client_config.current.project}"
  location      = var.primary_region
  force_destroy = false

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = var.kms_key_id
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 5
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  logging {
    log_bucket = google_storage_bucket.foundry_logs.id
  }

  labels = var.labels
}

# --- Media Assets Bucket (images, sounds, videos) ---
resource "google_storage_bucket" "foundry_media" {
  name          = "${var.project_name}-foundry-media-${data.google_client_config.current.project}"
  location      = var.primary_region
  force_destroy = false

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = var.kms_key_id
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 3
    }
    action {
      type = "Delete"
    }
  }

  logging {
    log_bucket = google_storage_bucket.foundry_logs.id
  }

  labels = var.labels
}

# --- Backups Bucket (database dumps, config exports) ---
resource "google_storage_bucket" "foundry_backups" {
  name          = "${var.project_name}-foundry-backups-${data.google_client_config.current.project}"
  location      = var.backup_location
  force_destroy = false

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = var.kms_key_id
  }

  # Backups older than 30 days -> COLDLINE for cost savings
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  # Backups older than 90 days -> ARCHIVE
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "ARCHIVE"
    }
  }

  # Backups older than 365 days -> DELETE (retention policy)
  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }

  logging {
    log_bucket = google_storage_bucket.foundry_logs.id
  }

  labels = var.labels
}

# --- Logging Bucket for audit trails ---
resource "google_storage_bucket" "foundry_logs" {
  name          = "${var.project_name}-foundry-logs-${data.google_client_config.current.project}"
  location      = var.primary_region
  force_destroy = false

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = false
  }

  encryption {
    default_kms_key_name = var.kms_key_id
  }

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }

  labels = var.labels
}

# --- IAM Binding: Allow Foundry compute to access data bucket ---
resource "google_storage_bucket_iam_member" "foundry_data_access" {
  bucket = google_storage_bucket.foundry_data.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.foundry_compute_sa_email}"
}

# --- IAM Binding: Allow Foundry compute to access media bucket ---
resource "google_storage_bucket_iam_member" "foundry_media_access" {
  bucket = google_storage_bucket.foundry_media.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.foundry_compute_sa_email}"
}

# --- IAM Binding: Allow backup service to access backups bucket ---
resource "google_storage_bucket_iam_member" "foundry_backups_access" {
  bucket = google_storage_bucket.foundry_backups.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.foundry_compute_sa_email}"
}

# --- Optional: Cloud CDN signed URLs for media delivery ---
# (Requires public read access; left as reference)
# resource "google_compute_backend_bucket" "foundry_media_cdn" {
#   name            = "${var.project_name}-media-cdn"
#   bucket_name     = google_storage_bucket.foundry_media.name
#   enable_cdn      = true
#   compression_mode = "AUTOMATIC"
#
#   cdn_policy {
#     cache_mode        = "CACHE_ALL_STATIC"
#     client_ttl        = 3600
#     default_ttl       = 3600
#     max_ttl           = 86400
#     negative_caching  = true
#     negative_caching_ttl = 120
#   }
# }

# --- Data source to get current project info ---
data "google_client_config" "current" {}
