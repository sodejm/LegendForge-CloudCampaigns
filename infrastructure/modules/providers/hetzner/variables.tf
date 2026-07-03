# =============================================================================
# infrastructure/modules/providers/hetzner/variables.tf
# =============================================================================
# LegendForge Hetzner provider configuration for cost-efficient universal tabletop infrastructure.
# Supports LegendForge's universal tabletop platform across multiple game systems.

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
variable "network_zone" {
  description = "Hetzner network zone (eu-central or us-west) for LegendForge's universal tabletop infrastructure."
  type        = string
  default     = "eu-central"
}

variable "network_cidr" {
  description = "IP range for the Hetzner private network hosting LegendForge infrastructure."
  type        = string
  default     = "10.0.0.0/8"
}

variable "subnet_cidr" {
  description = "Network CIDR range used by LegendForge's multi-system infrastructure for subnet cidr."
  type        = string
  default     = "10.0.0.0/24"
}

variable "network_cidr" {
  description = "Parent network CIDR range for Hetzner private networking."
  type        = string
  default     = "10.0.0.0/16"
}

# ===== Compute =====
variable "server_type" {
  description = "Hetzner server type used for LegendForge application nodes."
  type        = string
  default     = "cx21"
}

variable "datacenter" {
  description = "Hetzner datacenter that hosts LegendForge application resources."
  type        = string
  default     = "fsn1-dc14"
}

# ===== Storage =====
variable "data_volume_size_gb" {
  description = "Storage setting for LegendForge persistent worlds, assets, backups, or shared multi-system data."
  type        = number
  default     = 20
}

# ===== Spin up/down =====
variable "compute_enabled" {
  description = "Whether LegendForge application compute should be created or suspended while preserving shared data."
  type        = bool
  default     = true
}

# ===== SSH Break-glass =====
variable "admin_ssh_cidr" {
  description = "Optional break-glass CIDR allowed to administer LegendForge infrastructure over SSH."
  type        = string
  default     = null
}

# ===== LegendForge Configuration =====
variable "foundry_hostname" {
  description = "Public LegendForge hostname that routes players to the Foundry-powered multi-system experience."
  type        = string
}

variable "data_mount_path" {
  description = "Filesystem path where LegendForge persistent application data is mounted."
  type        = string
  default     = "/opt/foundry/data"
}

variable "data_volume_fs_label" {
  description = "Filesystem label used to mount LegendForge persistent application data reliably."
  type        = string
  default     = "FOUNDRY_DATA"
}

variable "foundry_image" {
  description = "Container image for the Foundry VTT runtime that powers LegendForge, ideally pinned by digest."
  type        = string
}

variable "cloudflared_image" {
  description = "Cloudflare Tunnel sidecar image used to publish LegendForge securely."
  type        = string
}

variable "timezone" {
  description = "IANA timezone applied to the LegendForge application runtime."
  type        = string
  default     = "America/New_York"
}

# ===== Secrets =====
variable "foundry_username" {
  description = "Foundry account username used by LegendForge for authenticated runtime downloads when required."
  type        = string
  default     = ""
  sensitive   = true
}

variable "foundry_password" {
  description = "Foundry account password used by LegendForge for authenticated runtime downloads when required."
  type        = string
  default     = ""
  sensitive   = true
}

variable "foundry_release_url" {
  description = "Optional Foundry release URL used by LegendForge instead of account credentials."
  type        = string
  default     = ""
  sensitive   = true
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
