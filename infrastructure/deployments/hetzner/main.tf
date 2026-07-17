# =============================================================================
# infrastructure/deployments/hetzner/main.tf
# =============================================================================
# LegendForge Hetzner deployment configuration for universal tabletop infrastructure with multi-system support.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# BUILT ON:
# - Foundry VTT: https://github.com/foundryvtt
# - felddy/foundryvtt Docker: https://github.com/felddy/foundryvtt-docker
# - Cloudflare Tunnel: https://www.cloudflare.com/products/tunnel/
# - Terraform: https://www.terraform.io/
# - Hetzner Provider: https://registry.terraform.io/providers/hetznercloud/hcloud/
#
# This configuration leverages excellent open-source and community projects.
# See ATTRIBUTION.md for full credits.
# =============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.40"
    }
  }
}

# ===== Provider Configuration Variables ===== for LegendForge multi-system operations.
variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
  default     = ""
}

variable "hcloud_token_env" {
  description = "Hetzner Cloud API token from environment"
  type        = string
  sensitive   = true
  default     = ""
}

provider "hcloud" {
  token = var.hcloud_token != "" ? var.hcloud_token : var.hcloud_token_env
}

# ===== Call the Hetzner module ===== for LegendForge multi-system operations.
module "foundry_hetzner" {
  source = "../../modules/providers/hetzner"

  project_name = var.project_name
  environment  = var.environment

  # Networking
  network_zone = var.network_zone
  subnet_cidr  = var.subnet_cidr

  # Compute
  server_type = var.server_type
  datacenter  = var.datacenter

  # Storage
  data_volume_size_gb = var.data_volume_size_gb

  # Spin up/down
  compute_enabled = var.compute_enabled

  # SSH break-glass
  admin_ssh_cidr = var.admin_ssh_cidr

  # LegendForge configuration
  foundry_hostname     = var.foundry_hostname
  data_mount_path      = var.data_mount_path
  data_volume_fs_label = var.data_volume_fs_label
  foundry_image        = var.foundry_image
  cloudflared_image    = var.cloudflared_image
  timezone             = var.timezone

  # Secrets
  foundry_username        = var.foundry_username
  foundry_password        = var.foundry_password
  foundry_release_url     = var.foundry_release_url
  foundry_license_key     = var.foundry_license_key
  foundry_admin_key       = var.foundry_admin_key
  cloudflare_tunnel_token = var.cloudflare_tunnel_token
}
