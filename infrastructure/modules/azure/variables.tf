# =============================================================================
# infrastructure/modules/azure/variables.tf
# =============================================================================
# LegendForge Azure variable definitions for universal tabletop infrastructure supporting multiple game systems.
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

variable "azure_region" {
  description = "Azure region where LegendForge's multi-system tabletop infrastructure is deployed."
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Azure resource group name that contains LegendForge infrastructure resources."
  type        = string
}

# ===== Networking =====
variable "vnet_cidr" {
  description = "Network CIDR range used by LegendForge's multi-system infrastructure for vnet cidr."
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "Network CIDR range used by LegendForge's multi-system infrastructure for subnet cidr."
  type        = string
  default     = "10.0.1.0/24"
}

variable "bastion_subnet_cidr" {
  description = "Network CIDR range used by LegendForge's multi-system infrastructure for bastion subnet cidr."
  type        = string
  default     = "10.0.255.0/27"
}

variable "enable_bastion" {
  description = "Whether to enable bastion for LegendForge's universal tabletop platform."
  type        = bool
  default     = false
}

# ===== Compute =====
variable "vm_size" {
  description = "Azure VM size used for LegendForge application nodes."
  type        = string
  default     = "Standard_B2s"
}

# ===== Storage =====
variable "data_disk_size_gb" {
  description = "Storage setting for LegendForge persistent worlds, assets, backups, or shared multi-system data."
  type        = number
  default     = 20
  validation {
    condition     = var.data_disk_size_gb >= 10
    error_message = "Data disk must be at least 10 GB."
  }
}

variable "data_disk_type" {
  description = "Storage setting for LegendForge persistent worlds, assets, backups, or shared multi-system data."
  type        = string
  default     = "Premium_LRS" # Premium SSD
  validation {
    condition     = contains(["Standard_LRS", "Premium_LRS", "StandardSSD_LRS", "UltraSSD_LRS"], var.data_disk_type)
    error_message = "Must be one of: Standard_LRS, Premium_LRS, StandardSSD_LRS, UltraSSD_LRS"
  }
}

# ===== Spin up/down =====
variable "compute_enabled" {
  description = "Whether LegendForge application compute should be created or suspended while preserving shared data."
  type        = bool
  default     = true
}

# ===== SSH Break-glass =====
variable "admin_username" {
  description = "Administrator username used for break-glass access to LegendForge compute resources."
  type        = string
  default     = "azureuser"
}

variable "admin_ssh_public_key" {
  description = "Public SSH key used for break-glass administration of LegendForge infrastructure."
  type        = string
  default     = ""
  sensitive   = true
}

variable "allow_ssh_cidr" {
  description = "Optional break-glass CIDR allowed to administer LegendForge infrastructure over SSH."
  type        = string
  default     = null
}

# ===== Monitoring =====
variable "enable_monitoring" {
  description = "Whether to enable monitoring for LegendForge's universal tabletop platform."
  type        = bool
  default     = true
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

# ===== Image Resource Group =====
variable "image_resource_group" {
  description = "Resource group containing the VM image for LegendForge's universal tabletop infrastructure."
  type        = string
  default     = "" # Use current resource group if empty
}
