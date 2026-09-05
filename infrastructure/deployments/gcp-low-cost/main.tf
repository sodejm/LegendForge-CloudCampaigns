terraform {
  required_version = ">= 1.7.0"
  required_providers {
    google = { source = "hashicorp/google", version = "~> 7.39" }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.region
  zone    = var.zone
}

resource "google_compute_network" "this" {
  name                    = var.name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "this" {
  name                     = var.name
  network                  = google_compute_network.this.id
  ip_cidr_range            = "10.42.1.0/24"
  region                   = var.region
  private_ip_google_access = true
}

resource "google_compute_firewall" "iap" {
  name          = "${var.name}-iap-ssh"
  network       = google_compute_network.this.name
  description   = "SSH only through authenticated Identity-Aware Proxy"
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["${var.name}-iap"]
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_service_account" "this" {
  account_id   = var.name
  display_name = "LegendForge single server (no project role grants)"
}

resource "google_compute_disk" "data" {
  name = "${var.name}-data"
  type = "pd-balanced"
  zone = var.zone
  size = var.data_disk_gb
  lifecycle {
    prevent_destroy = true
  }
}

module "app" {
  source = "../../modules/foundry-single-server"
  device = "/dev/disk/by-id/google-foundry-data"
  app    = var.app
}

resource "google_compute_instance" "this" {
  name                      = var.name
  machine_type              = var.instance_type
  zone                      = var.zone
  desired_status            = var.paused ? "TERMINATED" : "RUNNING"
  allow_stopping_for_update = true
  deletion_protection       = true
  tags                      = ["${var.name}-iap"]
  labels                    = { project = var.name, profile = "single-server" }
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = 20
      type  = "pd-balanced"
    }
  }
  attached_disk {
    source      = google_compute_disk.data.id
    device_name = "foundry-data"
  }
  network_interface {
    subnetwork = google_compute_subnetwork.this.id
    access_config {}
  }
  service_account {
    email  = google_service_account.this.email
    scopes = ["cloud-platform"]
  }
  metadata = {
    enable-oslogin         = "TRUE"
    block-project-ssh-keys = "TRUE"
    user-data              = module.app.user_data
  }
  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [boot_disk[0].initialize_params[0].image]
  }
}

output "instance_name" {
  description = "Instance to access with gcloud compute ssh --tunnel-through-iap."
  value       = google_compute_instance.this.name
}

output "data_disk_id" {
  description = "Independent retained disk; include it in snapshot and recovery records."
  value       = google_compute_disk.data.id
}

output "foundry_url" {
  description = "Public Foundry URL configured in the pre-created tunnel."
  value       = "https://${var.app.hostname}"
  sensitive   = true
}
