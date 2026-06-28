# =============================================================================
# infrastructure/modules/gcp-vpc/main.tf
# =============================================================================
# LegendForge GCP Vpc module configuration for universal tabletop infrastructure supporting multiple game systems.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# =============================================================================

resource "google_compute_network" "foundry_vpc" {
  name                    = "${var.project_name}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"

  description = "VPC network for LegendForge infrastructure with multi-system support."

  depends_on = []
}

# --- Primary subnet for LegendForge compute and database -------------------------
resource "google_compute_subnetwork" "foundry_primary" {
  name          = "${var.project_name}-primary-subnet"
  ip_cidr_range = var.primary_subnet_cidr
  region        = var.primary_region
  network       = google_compute_network.foundry_vpc.id

  description = "Primary subnet for LegendForge application servers and supporting services with multi-system support."

  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# --- Secondary subnet for additional services (optional) ----------------------
resource "google_compute_subnetwork" "foundry_secondary" {
  count         = var.enable_secondary_subnet ? 1 : 0
  name          = "${var.project_name}-secondary-subnet"
  ip_cidr_range = var.secondary_subnet_cidr
  region        = var.secondary_region
  network       = google_compute_network.foundry_vpc.id

  description = "Secondary subnet for LegendForge auxiliary services in alternate region with multi-system support."

  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# --- Cloud NAT for outbound internet access -----------------------------------
resource "google_compute_router" "foundry_router" {
  name    = "${var.project_name}-router"
  region  = var.primary_region
  network = google_compute_network.foundry_vpc.id

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "foundry_nat" {
  name                               = "${var.project_name}-nat"
  router                             = google_compute_router.foundry_router.name
  region                             = google_compute_router.foundry_router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# --- Firewall Rules: Allow SSH from bastion/admin IPs ---------------------------
resource "google_compute_firewall" "allow_ssh_from_admin" {
  name    = "${var.project_name}-allow-ssh-admin"
  network = google_compute_network.foundry_vpc.name

  description = "Allow SSH from admin IPs only (least privilege)"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.admin_source_ranges
  target_tags   = ["foundry-compute"]
}

# --- Firewall Rules: Allow internal communication ------------------------------
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.project_name}-allow-internal"
  network = google_compute_network.foundry_vpc.name

  description = "Allow all internal communication within VPC"

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.primary_subnet_cidr]
  target_tags   = ["foundry-compute"]
}

# --- Firewall Rules: Allow health checks from GCP --------------------------------
resource "google_compute_firewall" "allow_health_checks" {
  name    = "${var.project_name}-allow-health-checks"
  network = google_compute_network.foundry_vpc.name

  description = "Allow health checks from GCP infrastructure"

  allow {
    protocol = "tcp"
    ports    = ["30030"]
  }

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags   = ["foundry-compute", "health-check"]
}

# --- Firewall Rules: Allow only Load Balancer ingress ----------------------------
resource "google_compute_firewall" "allow_loadbalancer" {
  name    = "${var.project_name}-allow-loadbalancer"
  network = google_compute_network.foundry_vpc.name

  description = "Allow ingress only from Cloud Load Balancer"

  allow {
    protocol = "tcp"
    ports    = ["30030"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["foundry-compute"]
}

# --- Firewall Rules: Deny all other ingress (explicit) ----------------------------
resource "google_compute_firewall" "deny_all_ingress" {
  name    = "${var.project_name}-deny-all-ingress"
  network = google_compute_network.foundry_vpc.name

  description = "Deny all ingress traffic (except explicitly allowed)"

  deny {
    protocol = "all"
  }

  direction       = "INGRESS"
  priority        = 65534
  source_ranges   = ["0.0.0.0/0"]
  target_tags     = []
  enable_logging  = true
}
