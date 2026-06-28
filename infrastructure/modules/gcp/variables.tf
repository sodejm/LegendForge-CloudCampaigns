# =============================================================================
# infrastructure/modules/gcp/variables.tf
# =============================================================================
# LegendForge GCP variable definitions for universal tabletop infrastructure supporting multiple game systems.
# Supports LegendForge's universal tabletop platform across multiple game systems.

variable "project_id" {
  description = "Google Cloud project ID that hosts LegendForge's multi-system platform resources."
  type        = string
}

variable "region" {
  description = "GCP region where LegendForge's multi-system tabletop infrastructure is deployed."
  type        = string
  default     = "us-central1"
}

variable "project_name" {
  description = "LegendForge project slug used for consistent naming across universal tabletop infrastructure resources."
  type        = string
  default     = "legendforge"
}

variable "environment" {
  description = "LegendForge deployment environment (dev, staging, prod) used to scope multi-system infrastructure resources."
  type        = string
  default     = "prod"
}

# ===== Networking =====
variable "network_cidr" {
  description = "Network CIDR range used by LegendForge's multi-system infrastructure for network cidr."
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "Network CIDR range used by LegendForge's multi-system infrastructure for subnet cidr."
  type        = string
  default     = "10.0.1.0/24"
}

variable "nat_static_ip" {
  description = "Static IP for Cloud NAT (optional) for LegendForge's universal tabletop infrastructure."
  type        = string
  default     = ""
}

# ===== Compute =====
variable "machine_type" {
  description = "Compute machine type used for LegendForge platform services."
  type        = string
  default     = "e2-medium"
}

variable "zone" {
  description = "GCP zone (defaults to region-a) for LegendForge's universal tabletop infrastructure."
  type        = string
  default     = ""
}

# ===== Storage =====
variable "disk_size_gb" {
  description = "Storage setting for LegendForge persistent worlds, assets, backups, or shared multi-system data."
  type        = number
  default     = 20
}

variable "disk_type" {
  description = "Storage setting for LegendForge persistent worlds, assets, backups, or shared multi-system data."
  type        = string
  default     = "pd-ssd"
}

# ===== Spin up/down =====
variable "compute_enabled" {
  description = "Whether LegendForge application compute should be created or suspended while preserving shared data."
  type        = bool
  default     = true
}

# ===== Monitoring =====
variable "enable_monitoring" {
  description = "Whether to enable monitoring for LegendForge's universal tabletop platform."
  type        = bool
  default     = true
}

# ===== LegendForge Configuration =====
variable "foundry_hostname" {
  description = "Public LegendForge hostname that routes players to the Foundry-powered multi-system experience."
  type        = string
}

variable "foundry_license_key" {
  description = "Foundry VTT license key consumed by the LegendForge application runtime."
  type        = string
  sensitive   = true
}

variable "foundry_admin_key" {
  description = "LegendForge administrator/setup password for the Foundry application runtime."
  type        = string
  sensitive   = true
}

variable "cloudflare_tunnel_token" {
  description = "Cloudflare Tunnel token that exposes LegendForge's multi-system service securely."
  type        = string
  sensitive   = true
}

variable "foundry_image" {
  description = "Container image for the Foundry VTT runtime that powers LegendForge, ideally pinned by digest."
  type        = string
  default     = "felddy/foundryvtt@sha256:abc123"
}

variable "cloudflared_image" {
  description = "Cloudflare Tunnel sidecar image used to publish LegendForge securely."
  type        = string
  default     = "cloudflare/cloudflared@sha256:abc123"
}
