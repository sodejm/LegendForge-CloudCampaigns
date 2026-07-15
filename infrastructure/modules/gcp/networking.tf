# =============================================================================
# GCP Networking — VPC, Subnets, Firewall, Cloud NAT
# =============================================================================

# ===== VPC Network =====
resource "google_compute_network" "foundry" {
  name                    = "${local.name_prefix}-network"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"

  project = var.project_id
}

# ===== Subnet =====
resource "google_compute_subnetwork" "foundry" {
  name          = "${local.name_prefix}-subnet"
  ip_cidr_range = local.subnet_cidr
  region        = var.region
  network       = google_compute_network.foundry.id

  project = var.project_id

  labels = local.common_labels
}

# ===== Cloud Router (for Cloud NAT) =====
resource "google_compute_router" "foundry" {
  name    = "${local.name_prefix}-router"
  region  = var.region
  network = google_compute_network.foundry.id
  project = var.project_id

  bgp {
    asn = 64514
  }

  labels = local.common_labels
}

# ===== Cloud NAT =====
resource "google_compute_router_nat" "foundry" {
  name                               = "${local.name_prefix}-nat"
  router                             = google_compute_router.foundry.name
  region                             = google_compute_router.foundry.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }

  project = var.project_id
}

# ===== Firewall: Allow egress HTTPS (for Cloudflare Tunnel) =====
resource "google_compute_firewall" "egress_https" {
  name    = "${local.name_prefix}-allow-egress-https"
  network = google_compute_network.foundry.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  direction          = "EGRESS"
  destination_ranges = ["0.0.0.0/0"]

  target_tags = ["foundry-app"]
}

# ===== Firewall: Allow egress DNS (for package updates) =====
resource "google_compute_firewall" "egress_dns" {
  name    = "${local.name_prefix}-allow-egress-dns"
  network = google_compute_network.foundry.name
  project = var.project_id

  allow {
    protocol = "udp"
    ports    = ["53"]
  }

  direction          = "EGRESS"
  destination_ranges = ["0.0.0.0/0"]

  target_tags = ["foundry-app"]
}

# ===== Firewall: Deny all ingress (default deny) =====
resource "google_compute_firewall" "deny_ingress" {
  name    = "${local.name_prefix}-deny-ingress"
  network = google_compute_network.foundry.name
  project = var.project_id

  deny {
    protocol = "tcp"
  }

  deny {
    protocol = "udp"
  }

  deny {
    protocol = "icmp"
  }

  priority      = 65534
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]

  target_tags = ["foundry-app"]
}
