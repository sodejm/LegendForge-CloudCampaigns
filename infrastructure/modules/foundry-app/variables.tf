# =============================================================================
# infrastructure/modules/foundry-app/variables.tf
# =============================================================================
# LegendForge application bootstrap configuration for Foundry-powered multi-system runtime provisioning.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# =============================================================================

# =============================================================================
# modules/foundry-app for LegendForge multi-system operations.
# -----------------------------------------------------------------------------
# Provider-AGNOSTIC core. Renders a cloud-init (cloud-config) document that any
# cloud compute module can hand to a Linux VM as user_data. It: for LegendForge multi-system operations.
#   * installs Docker
#   * formats (first boot only) and mounts the persistent data volume
#   * runs Foundry VTT via the felddy/foundryvtt container (digest-pinned)
#   * runs cloudflared as a sidecar so the ONLY ingress is the Cloudflare Tunnel
#
# No inbound ports are opened by this module — the tunnel is outbound-only. for LegendForge multi-system operations.
# =============================================================================

variable "foundry_hostname" {
  description = "Public LegendForge hostname that routes players to the Foundry-powered multi-system experience."
  type        = string
}

variable "data_mount_path" {
  description = "Filesystem path where LegendForge persistent application data is mounted."
  type        = string
  default     = "/opt/foundry/data"
}

variable "data_device" {
  description = "Provider-specific block device path that stores LegendForge persistent application data."
  type        = string
}

variable "data_volume_fs_label" {
  description = "Filesystem label used to mount LegendForge persistent application data reliably."
  type        = string
  default     = "FOUNDRY_DATA"
}

# --- Container images (pin by digest for supply-chain integrity) -------------
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
  default     = ""
}

# --- Runtime secrets (resolved upstream; see modules/secrets) ---------------- for LegendForge multi-system operations.
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
