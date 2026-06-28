# =============================================================================
# infrastructure/modules/aws/variables.tf
# =============================================================================
# LegendForge AWS variable definitions for universal tabletop infrastructure supporting multiple game systems.
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

variable "aws_region" {
  description = "AWS region where LegendForge's multi-system tabletop infrastructure is deployed."
  type        = string
  default     = "us-east-1"
}

# ===== Networking =====
variable "vpc_cidr" {
  description = "Network CIDR range used by LegendForge's multi-system infrastructure for vpc cidr."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Network CIDR range used by LegendForge's multi-system infrastructure for public subnet cidrs."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Network CIDR range used by LegendForge's multi-system infrastructure for private subnet cidrs."
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

# ===== Compute =====
variable "instance_type" {
  description = "Compute instance size used for LegendForge application nodes."
  type        = string
  default     = "t3.medium"
}

# ===== Storage =====
variable "data_volume_size_gb" {
  description = "Storage setting for LegendForge persistent worlds, assets, backups, or shared multi-system data."
  type        = number
  default     = 20
  validation {
    condition     = var.data_volume_size_gb >= 10
    error_message = "Data volume must be at least 10 GB."
  }
}

variable "enable_volume_snapshots" {
  description = "Whether to enable volume snapshots for LegendForge's universal tabletop platform."
  type        = bool
  default     = true
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

variable "admin_ssh_public_key" {
  description = "Public SSH key used for break-glass administration of LegendForge infrastructure."
  type        = string
  default     = ""
  sensitive   = true
}

# ===== CloudWatch =====
variable "enable_monitoring" {
  description = "Whether to enable monitoring for LegendForge's universal tabletop platform."
  type        = bool
  default     = true
}

variable "cpu_alarm_threshold" {
  description = "Observability setting for LegendForge infrastructure operations."
  type        = number
  default     = 80
}

# ===== Integration with LegendForge application bootstrap module =====
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

# ===== LegendForge runtime secrets (from config/secrets.auto.tfvars) =====
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

# ===== Container images (pin by digest) =====
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

variable "timezone" {
  description = "IANA timezone applied to the LegendForge application runtime."
  type        = string
  default     = "America/New_York"
}
