# =============================================================================
# infrastructure/modules/gcp-iam/main.tf
# =============================================================================
# LegendForge GCP Iam module configuration for universal tabletop infrastructure supporting multiple game systems.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# Follows least-privilege principle.
# =============================================================================

# --- Service Account for LegendForge Compute instances ---------------------------
resource "google_service_account" "foundry_compute" {
  account_id   = "${var.project_name}-foundry-compute"
  display_name = "Foundry VTT Compute Instances"
  description  = "Service account for LegendForge application VMs with multi-system support."
}

# --- Service Account for Cloud SQL -----------------------------------------------
resource "google_service_account" "foundry_cloudsql" {
  account_id   = "${var.project_name}-foundry-cloudsql"
  display_name = "Foundry VTT Cloud SQL"
  description  = "Service account for Cloud SQL proxy and backups"
}

# --- Service Account for Cloud Storage (backups & media) ----------------------
resource "google_service_account" "foundry_storage" {
  account_id   = "${var.project_name}-foundry-storage"
  display_name = "Foundry VTT Storage"
  description  = "Service account for Cloud Storage access (backups, media, worlds)"
}

# --- Service Account for Monitoring & Logging ---------------------------------
resource "google_service_account" "foundry_monitoring" {
  account_id   = "${var.project_name}-foundry-monitoring"
  display_name = "Foundry VTT Monitoring"
  description  = "Service account for Cloud Monitoring, Logging, and Error Reporting"
}

# --- Service Account for Secret Manager access --------------------------------
resource "google_service_account" "foundry_secrets" {
  account_id   = "${var.project_name}-foundry-secrets"
  display_name = "Foundry VTT Secrets Manager"
  description  = "Service account for accessing GCP Secret Manager"
}

# =============================================================================
# IAM Bindings for LegendForge Compute Service Account
# =============================================================================

# Logging agent permissions
resource "google_project_iam_member" "compute_logs_writer" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.foundry_compute.email}"
}

# Monitoring metrics writer
resource "google_project_iam_member" "compute_metrics_writer" {
  project = var.gcp_project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.foundry_compute.email}"
}

# Cloud Monitoring viewer (for agent diagnostics)
resource "google_project_iam_member" "compute_monitoring_viewer" {
  project = var.gcp_project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.foundry_compute.email}"
}

# Secret Manager secret accessor (for LegendForge license keys, etc)
resource "google_project_iam_member" "compute_secret_accessor" {
  project = var.gcp_project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.foundry_compute.email}"
}

# Compute instance metadata reader
resource "google_project_iam_member" "compute_instance_admin" {
  project = var.gcp_project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${google_service_account.foundry_compute.email}"
}

# =============================================================================
# IAM Bindings for Cloud SQL Service Account
# =============================================================================

# Cloud SQL Client (connect via proxy)
resource "google_project_iam_member" "cloudsql_client" {
  project = var.gcp_project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.foundry_cloudsql.email}"
}

# Cloud SQL Instance User (deprecated but still used for instance operations)
resource "google_project_iam_member" "cloudsql_viewer" {
  project = var.gcp_project_id
  role    = "roles/cloudsql.viewer"
  member  = "serviceAccount:${google_service_account.foundry_cloudsql.email}"
}

# Logging agent permissions
resource "google_project_iam_member" "cloudsql_logs_writer" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.foundry_cloudsql.email}"
}

# =============================================================================
# IAM Bindings for Cloud Storage Service Account
# =============================================================================

# Storage Object Admin (for full access to storage buckets)
resource "google_project_iam_member" "storage_admin" {
  project = var.gcp_project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.foundry_storage.email}"
}

# Storage Bucket Admin (for bucket lifecycle management)
resource "google_project_iam_member" "storage_bucket_admin" {
  project = var.gcp_project_id
  role    = "roles/storage.bucketAdmin"
  member  = "serviceAccount:${google_service_account.foundry_storage.email}"
}

# Logging agent permissions
resource "google_project_iam_member" "storage_logs_writer" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.foundry_storage.email}"
}

# =============================================================================
# IAM Bindings for Monitoring Service Account
# =============================================================================

# Monitoring Admin (for dashboards and alerts)
resource "google_project_iam_member" "monitoring_admin" {
  project = var.gcp_project_id
  role    = "roles/monitoring.admin"
  member  = "serviceAccount:${google_service_account.foundry_monitoring.email}"
}

# Logging Admin (for log queries and analysis)
resource "google_project_iam_member" "monitoring_logs_viewer" {
  project = var.gcp_project_id
  role    = "roles/logging.viewer"
  member  = "serviceAccount:${google_service_account.foundry_monitoring.email}"
}

# Error Reporting Viewer
resource "google_project_iam_member" "monitoring_error_viewer" {
  project = var.gcp_project_id
  role    = "roles/errorreporting.viewer"
  member  = "serviceAccount:${google_service_account.foundry_monitoring.email}"
}

# =============================================================================
# IAM Bindings for Secrets Service Account
# =============================================================================

# Secret Manager Secret Accessor (minimal permissions)
resource "google_project_iam_member" "secrets_accessor" {
  project = var.gcp_project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.foundry_secrets.email}"
}

# =============================================================================
# Custom IAM Role for LegendForge Compute (more granular control)
# =============================================================================

resource "google_project_iam_custom_role" "foundry_compute_role" {
  role_id     = "${replace(var.project_name, "-", "_")}_foundry_compute"
  title       = "Foundry VTT Compute Custom Role"
  description = "Custom role with minimal permissions for LegendForge compute instances with multi-system support."

  permissions = [
    "compute.instances.get",
    "compute.instances.list",
    "compute.disks.get",
    "compute.disks.list",
    "compute.networks.get",
    "compute.subnetworks.get",
    "logging.logEntries.create",
    "monitoring.timeSeries.create",
    "monitoring.timeSeries.get",
    "monitoring.timeSeries.list",
  ]
}

# =============================================================================
# Workload Identity Setup (for pod-to-GCP authentication)
# =============================================================================

# This is optional - only needed if using GKE; for Compute Engine instances,
# the service account is attached directly to the VM.

# For reference: If using GKE, you would bind k8s SA to GCP SA like:
# resource "google_service_account_iam_member" "foundry_k8s_workload_identity" {
#   service_account_id = google_service_account.foundry_compute.name
#   role               = "roles/iam.workloadIdentityUser"
#   member             = "serviceAccount:${var.gcp_project_id}.svc.id.goog[foundry/foundry-app]"
# }
