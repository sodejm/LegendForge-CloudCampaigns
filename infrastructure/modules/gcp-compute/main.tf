# =============================================================================
# infrastructure/modules/gcp-compute/main.tf
# =============================================================================
# LegendForge GCP Compute module configuration for universal tabletop infrastructure supporting multiple game systems.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# - Instance template with cloud-init bootstrapping
# - Persistent disks for application data
# - Health checks and load balancer integration
# =============================================================================

# --- Instance Template ---
resource "google_compute_instance_template" "foundry" {
  name_prefix = "${var.project_name}-foundry-"
  description = "Instance template for LegendForge application with multi-system support."

  machine_type = var.machine_type
  region       = var.primary_region

  # Instance properties
  service_account {
    email = var.foundry_compute_sa_email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  # Root boot disk (100 GB)
  disk {
    source_image = var.boot_disk_image
    disk_type    = "pd-standard"
    disk_size_gb = 100
    auto_delete  = true
    boot         = true

    disk_encryption_key {
      kms_key_self_link = var.kms_key_id != "" ? var.kms_key_id : null
    }
  }

  # Persistent data disk (500 GB by default)
  disk {
    type            = "PERSISTENT"
    disk_type       = "pd-ssd"
    disk_size_gb    = var.data_disk_size_gb
    device_name     = "foundry-data"
    auto_delete     = false
    source_image    = null
    source_snapshot = null

    disk_encryption_key {
      kms_key_self_link = var.kms_key_id != "" ? var.kms_key_id : null
    }
  }

  # Network interface
  network_interface {
    network    = var.vpc_network_name
    subnetwork = var.subnet_name
    network_ip = null # Assigned automatically

    access_config {
      nat_ip = null # No public IP (behind load balancer)
    }
  }

  # Metadata and startup script
  metadata = {
    enable-oslogin         = "TRUE"
    user-data              = var.startup_script
    block-project-ssh-keys = "FALSE"
  }

  # Labels
  labels = var.labels

  # Shielded VM security
  shielded_vm_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  # Tags
  tags = ["foundry-compute", "health-check"]

  lifecycle {
    create_before_destroy = true
  }
}

# --- Instance Group Manager with Auto-Scaling ---
resource "google_compute_region_instance_group_manager" "foundry" {
  name   = "${var.project_name}-foundry-igm"
  region = var.primary_region

  base_instance_name = "${var.project_name}-foundry"
  instance_template  = google_compute_instance_template.foundry.id

  # Initial target size (can be overridden by autoscaler)
  target_size = var.min_instances

  # Rolling update strategy
  update_policy {
    max_surge       = 1
    max_unavailable = 0
    type            = "PROACTIVE"
    minimal_action  = "RESTART"
  }

  # Auto-healing with health checks
  auto_healing_policies {
    health_check      = google_compute_health_check.foundry_http.id
    initial_delay_sec = 300
  }

  named_port {
    name = "foundry"
    port = 30030
  }

  depends_on = [
    google_compute_instance_template.foundry
  ]
}

# --- Health Check ---
resource "google_compute_health_check" "foundry_http" {
  name        = "${var.project_name}-foundry-health-check"
  description = "HTTP health check for LegendForge with multi-system support."

  check_interval_sec  = 30
  timeout_sec         = 10
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = "30030"
    request_path = "/"
    proxy_header = "NONE"
  }

  log_config {
    enable = true
  }
}

# --- CPU Autoscaler ---
resource "google_compute_region_autoscaler" "foundry_cpu" {
  name   = "${var.project_name}-foundry-autoscaler-cpu"
  region = var.primary_region
  target = google_compute_region_instance_group_manager.foundry.id

  autoscaling_policy {
    min_replicas    = var.min_instances
    max_replicas    = var.max_instances
    cooldown_period = 60

    cpu_utilization {
      target = var.cpu_target_utilization
    }
  }
}

# --- Memory Autoscaler (if available) ---
# Note: GCP memory autoscaling works via custom metrics
resource "google_compute_region_autoscaler" "foundry_memory" {
  count  = var.enable_memory_autoscaling ? 1 : 0
  name   = "${var.project_name}-foundry-autoscaler-memory"
  region = var.primary_region
  target = google_compute_region_instance_group_manager.foundry.id

  autoscaling_policy {
    min_replicas    = var.min_instances
    max_replicas    = var.max_instances
    cooldown_period = 60

    metric {
      name   = "custom.googleapis.com/memory_utilization"
      target = var.memory_target_utilization
    }
  }
}

# --- Firewall rule for load balancer to reach instances ---
resource "google_compute_firewall" "foundry_lb" {
  name    = "${var.project_name}-foundry-lb"
  network = var.vpc_network_name

  allow {
    protocol = "tcp"
    ports    = ["30030"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["foundry-compute"]
}

# --- Output instance group information ---
output "instance_group_name" {
  value = google_compute_region_instance_group_manager.foundry.name
}

output "instance_group_id" {
  value = google_compute_region_instance_group_manager.foundry.id
}

output "instance_group_manager_id" {
  value = google_compute_region_instance_group_manager.foundry.id
}

output "health_check_id" {
  value = google_compute_health_check.foundry_http.id
}
