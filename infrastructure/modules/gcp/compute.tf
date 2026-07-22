# =============================================================================
# GCP Compute — Compute Engine Instance, Service Account, Cloud Init
# =============================================================================

# ===== Service Account =====
resource "google_service_account" "foundry" {
  account_id   = "${local.name_prefix}-sa"
  display_name = "Foundry VTT Service Account"
  project      = var.project_id
}

# ===== Service Account IAM Roles =====
resource "google_project_iam_member" "foundry_secret_reader" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.foundry.email}"
}

resource "google_project_iam_member" "foundry_monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.foundry.email}"
}

# ===== Compute Instance =====
resource "google_compute_instance" "foundry" {
  count            = var.compute_enabled ? 1 : 0
  name             = "${local.name_prefix}-instance"
  machine_type     = local.machine_type
  zone             = var.zone != "" ? var.zone : "${var.region}-a"
  project          = var.project_id
  min_cpu_platform = "Automatic"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = local.boot_disk_size_gb
      type  = "pd-ssd"
    }

    auto_delete = true
  }

  # Persistent data disk
  attached_disk {
    source      = google_compute_disk.foundry_data[0].self_link
    device_name = "foundry-data"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.foundry.self_link

    # No public IP - use Cloud NAT for egress
    access_config {
      # Empty access_config enables ephemeral public IP
      # Comment out for truly private instance
    }
  }

  # User data / Cloud Init + OS Login (security best practice)
  metadata = {
    user-data      = module.foundry_app.user_data_raw
    enable-oslogin = "TRUE"
  }

  # Service account
  service_account {
    email  = google_service_account.foundry.email
    scopes = ["cloud-platform"]
  }

  labels = local.common_labels
  tags   = ["foundry-app"]

  depends_on = [
    google_compute_disk.foundry_data,
    google_service_account.foundry
  ]
}

# ===== Persistent Disk for Foundry Data =====
resource "google_compute_disk" "foundry_data" {
  count   = var.compute_enabled ? 1 : 0
  name    = "${local.name_prefix}-data-disk"
  type    = var.disk_type
  size    = var.disk_size_gb
  zone    = var.zone != "" ? var.zone : "${var.region}-a"
  project = var.project_id

  labels = local.common_labels
}

# ===== Disk Snapshot Schedule =====
resource "google_compute_resource_policy" "daily_snapshot" {
  count       = var.compute_enabled ? 1 : 0
  name        = "${local.name_prefix}-daily-snapshot"
  description = "Daily snapshot of Foundry data disk"
  project     = var.project_id
  region      = var.region

  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = "02:00" # 2 AM UTC
      }
    }

    retention_policy {
      max_retention_days = 30
    }

    snapshot_properties {
      labels = local.common_labels
    }
  }
}

# ===== Attach snapshot schedule to disk =====
resource "google_compute_disk_resource_policy_attachment" "foundry_data_snapshots" {
  count   = var.compute_enabled ? 1 : 0
  name    = google_compute_resource_policy.daily_snapshot[0].name
  disk    = google_compute_disk.foundry_data[0].name
  zone    = google_compute_disk.foundry_data[0].zone
  project = var.project_id
}

# ===== Foundry App Module (Provider-agnostic cloud-init) =====
module "foundry_app" {
  source = "../../modules/foundry-app"

  foundry_hostname        = var.foundry_hostname
  data_device             = "/dev/disk/by-id/google-foundry-data"
  data_mount_path         = "/opt/foundry/data"
  data_volume_fs_label    = "FOUNDRY_DATA"
  foundry_image           = var.foundry_image
  cloudflared_image       = var.cloudflared_image
  timezone                = "America/New_York"
  foundry_license_key     = var.foundry_license_key
  foundry_admin_key       = var.foundry_admin_key
  cloudflare_tunnel_token = var.cloudflare_tunnel_token
}
