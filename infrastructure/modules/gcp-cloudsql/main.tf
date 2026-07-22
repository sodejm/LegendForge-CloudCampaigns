# =============================================================================
# infrastructure/modules/gcp-cloudsql/main.tf
# =============================================================================
# LegendForge GCP Cloudsql module configuration for universal tabletop infrastructure supporting multiple game systems.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# =============================================================================

resource "google_sql_database_instance" "foundry_primary" {
  name             = "${var.project_name}-foundry-db"
  database_version = var.database_version
  region           = var.primary_region

  settings {
    tier              = var.machine_type
    availability_type = "REGIONAL" # High Availability with failover replica

    # Backup configuration
    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
      backup_retention_settings {
        retained_backups = 30
        retention_unit   = "COUNT"
      }
      location                       = var.backup_location
      start_time                     = "02:00"
      transaction_log_retention_days = 7
    }

    # Database flags
    database_flags {
      name  = "max_connections"
      value = var.max_connections
    }

    database_flags {
      name  = "shared_buffers"
      value = var.shared_buffers
    }

    database_flags {
      name  = "effective_cache_size"
      value = var.effective_cache_size
    }

    # IP configuration
    ip_configuration {
      ssl_mode           = "ENCRYPTED_ONLY"
      ipv4_enabled       = var.enable_public_ip
      private_network    = var.vpc_network_id
      allocated_ip_range = null

      authorized_networks {
        name  = "gcp-internal"
        value = var.primary_subnet_cidr
      }
    }

    # Maintenance window
    maintenance_window {
      day          = 0 # Sunday
      hour         = 3
      update_track = "stable"
    }

    # Insights configuration (for performance monitoring)
    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = false
    }
    # User labels
    user_labels = var.labels
  }

  deletion_protection = var.deletion_protection

  depends_on = [var.vpc_network_id]
}

# --- LegendForge platform database ---
resource "google_sql_database" "foundry" {
  name     = var.foundry_database_name
  instance = google_sql_database_instance.foundry_primary.name
  charset  = "UTF8"
}

# --- Database user for LegendForge application ---
resource "random_password" "db_user_password" {
  length  = 32
  special = true
}

resource "google_sql_user" "foundry_app" {
  name     = var.foundry_db_user
  instance = google_sql_database_instance.foundry_primary.name
  password = random_password.db_user_password.result
  type     = "BUILT_IN"
}

# --- Database user for backups and monitoring ---
resource "random_password" "db_backup_user_password" {
  length  = 32
  special = true
}

resource "google_sql_user" "foundry_backup" {
  name     = var.foundry_backup_user
  instance = google_sql_database_instance.foundry_primary.name
  password = random_password.db_backup_user_password.result
  type     = "BUILT_IN"
}

# --- Read replica for disaster recovery (optional) ---
resource "google_sql_database_instance" "foundry_replica" {
  count = var.enable_read_replica ? 1 : 0

  name                 = "${var.project_name}-foundry-db-replica"
  database_version     = var.database_version
  region               = var.replica_region
  master_instance_name = google_sql_database_instance.foundry_primary.name

  replica_configuration {
    failover_target = true
  }

  settings {
    tier              = var.machine_type
    availability_type = "ZONAL"

    ip_configuration {
      ssl_mode        = "ENCRYPTED_ONLY"
      ipv4_enabled    = false
      private_network = var.vpc_network_id
    }

    user_labels = var.labels
  }
}

# --- SSL Certificates for encrypted connections ---
resource "google_sql_ssl_cert" "foundry_ssl" {
  common_name = "foundry-app"
  instance    = google_sql_database_instance.foundry_primary.name
}
