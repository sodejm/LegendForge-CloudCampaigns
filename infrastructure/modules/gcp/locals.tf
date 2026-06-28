# =============================================================================
# GCP Locals — Common values and naming conventions
# =============================================================================

locals {
  project = var.project_name
  env     = var.environment

  # GCP naming convention (lowercase, hyphens)
  name_prefix = "${local.project}-${local.env}"

  # Common labels applied to all resources
  common_labels = {
    project     = local.project
    environment = local.env
    managed-by  = "terraform"
  }

  # Networking defaults
  network_cidr   = var.network_cidr
  subnet_cidr    = var.subnet_cidr
  nat_ip_address = var.nat_static_ip

  # Compute defaults
  machine_type      = var.machine_type
  boot_disk_size_gb = 30
}
