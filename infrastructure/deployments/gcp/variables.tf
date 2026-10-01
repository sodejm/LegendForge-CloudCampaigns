# =============================================================================
# infrastructure/deployments/gcp/variables.tf
# =============================================================================
# LegendForge GCP deployment configuration for universal tabletop infrastructure with multi-system support.
# Supports LegendForge's universal tabletop platform across multiple game systems.

variable "gcp_project_id" {
  description = "Google Cloud project ID that hosts LegendForge's multi-system platform resources."
  type        = string
}

variable "project_name" {
  description = "LegendForge project slug used for consistent naming across universal tabletop infrastructure resources."
  type        = string
  default     = "legendforge"
}

# =============================================================================
# Regional Configuration
# =============================================================================

variable "primary_region" {
  description = "Primary region for LegendForge production traffic and stateful services."
  type        = string
  default     = "us-central1"
}

variable "secondary_region" {
  description = "Secondary region used for LegendForge disaster recovery or multi-region failover."
  type        = string
  default     = "us-east1"
}

variable "enable_multi_region" {
  description = "Whether to enable multi region for LegendForge's universal tabletop platform."
  type        = bool
  default     = false
}

variable "backup_location" {
  description = "Backup location (us, eu, asia) for LegendForge's universal tabletop infrastructure."
  type        = string
  default     = "us"
}

# =============================================================================
# Network Configuration
# =============================================================================

variable "primary_subnet_cidr" {
  description = "Network CIDR range used by LegendForge's multi-system infrastructure for primary subnet cidr."
  type        = string
  default     = "10.0.0.0/20"
}

variable "secondary_subnet_cidr" {
  description = "Network CIDR range used by LegendForge's multi-system infrastructure for secondary subnet cidr."
  type        = string
  default     = "10.16.0.0/20"
}

variable "admin_source_ranges" {
  description = "CIDR ranges allowed for SSH admin access for LegendForge's universal tabletop infrastructure; defaults to IAP TCP forwarding."
  type        = list(string)
  default     = ["35.235.240.0/20"]
}

# =============================================================================
# Compute Configuration
# =============================================================================

variable "compute_machine_type" {
  description = "GCP machine type for compute instances for LegendForge's universal tabletop infrastructure."
  type        = string
  default     = "n2-standard-2" # 2 vCPU, 8GB RAM
}

variable "boot_disk_image" {
  description = "Storage setting for LegendForge persistent worlds, assets, backups, or shared multi-system data."
  type        = string
  default     = "ubuntu-2404-lts"
}

variable "data_disk_size_gb" {
  description = "Storage setting for LegendForge persistent worlds, assets, backups, or shared multi-system data."
  type        = number
  default     = 500
}

variable "min_instances" {
  description = "Minimum number of instances in instance group for LegendForge's universal tabletop infrastructure."
  type        = number
  default     = 2
}

variable "max_instances" {
  description = "Maximum number of instances for autoscaling for LegendForge's universal tabletop infrastructure."
  type        = number
  default     = 5
}

variable "cpu_target_utilization" {
  description = "Target CPU utilization for autoscaling (0.0-1.0) for LegendForge's universal tabletop infrastructure."
  type        = number
  default     = 0.7

  validation {
    condition     = var.cpu_target_utilization > 0 && var.cpu_target_utilization <= 1
    error_message = "CPU target utilization must be between 0 and 1."
  }
}

variable "enable_memory_autoscaling" {
  description = "Whether to enable memory autoscaling for LegendForge's universal tabletop platform."
  type        = bool
  default     = false
}

# =============================================================================
# Cloud SQL Configuration
# =============================================================================

variable "cloudsql_machine_type" {
  description = "Database setting used by LegendForge's persistent multi-system data services."
  type        = string
  default     = "db-custom-2-7680" # 2 vCPU, 7.5 GB RAM
}

variable "database_version" {
  description = "Database setting used by LegendForge's persistent multi-system data services."
  type        = string
  default     = "POSTGRES_15"
}

variable "foundry_database_name" {
  description = "Resource name used by LegendForge infrastructure for foundry database name."
  type        = string
  default     = "foundry"
}

variable "foundry_db_user" {
  description = "Database setting used by LegendForge's persistent multi-system data services."
  type        = string
  default     = "foundry_app"
}

variable "foundry_backup_user" {
  description = "Database user for backups for LegendForge's universal tabletop infrastructure."
  type        = string
  default     = "foundry_backup"
}

variable "enable_cloudsql_public_ip" {
  description = "Whether to enable cloudsql public ip for LegendForge's universal tabletop platform."
  type        = bool
  default     = false
}

# =============================================================================
# Security & Secrets
# =============================================================================

variable "database_password" {
  description = "Database password used by LegendForge stateful services and supporting multi-system data workloads."
  type        = string
  sensitive   = true
  default     = "GENERATE_RANDOM" # Will be overridden
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

variable "foundry_username" {
  description = "Foundry account username used by LegendForge for authenticated runtime downloads when required."
  type        = string
  sensitive   = true
  default     = ""
}

variable "foundry_password" {
  description = "Foundry account password used by LegendForge for authenticated runtime downloads when required."
  type        = string
  sensitive   = true
  default     = ""
}

variable "cloudflare_tunnel_token" {
  description = "Cloudflare Tunnel token that exposes LegendForge's multi-system service securely."
  type        = string
  sensitive   = true
}

variable "enable_deletion_protection" {
  description = "Whether to enable deletion protection for LegendForge's universal tabletop platform."
  type        = bool
  default     = true
}

# =============================================================================
# LegendForge Configuration
# =============================================================================

variable "foundry_hostname" {
  description = "Public LegendForge hostname that routes players to the Foundry-powered multi-system experience."
  type        = string
}

variable "domain_name" {
  description = "Primary LegendForge domain used for certificates, ingress, and multi-system player access."
  type        = string
}

# =============================================================================
# Load Balancer Configuration
# =============================================================================

variable "enable_cdn" {
  description = "Whether to enable cdn for LegendForge's universal tabletop platform."
  type        = bool
  default     = true
}

variable "enable_cloud_armor" {
  description = "Attach the Cloud Armor policy to the active Foundry backend. Disabling attachment retains the policy resource."
  type        = bool
  default     = true
}

variable "cloud_armor_preview" {
  description = "Preview WAF and rate-limit rules without blocking requests. Disable only after tuning and live acceptance."
  type        = bool
  default     = true
}

variable "cloud_armor_rate_limit_count" {
  description = "Requests per client IP per interval for the rate-based ban rule; tune for asset bursts and shared player IPs."
  type        = number
  default     = 100

  validation {
    condition     = var.cloud_armor_rate_limit_count >= 1 && var.cloud_armor_rate_limit_count <= 10000 && floor(var.cloud_armor_rate_limit_count) == var.cloud_armor_rate_limit_count
    error_message = "The rate-based ban count must be an integer from 1 through 10000."
  }
}

variable "cloud_armor_rate_limit_interval_sec" {
  description = "Cloud Armor rate-limit interval in seconds."
  type        = number
  default     = 60

  validation {
    condition     = contains([10, 30, 60, 120, 180, 240, 300, 600, 900, 1200, 1800, 2700, 3600], var.cloud_armor_rate_limit_interval_sec)
    error_message = "The interval must be 10, 30, 60, 120, 180, 240, 300, 600, 900, 1200, 1800, 2700 or 3600 seconds."
  }
}

variable "cloud_armor_ban_duration_sec" {
  description = "Additional ban duration after the rate-limit interval, in seconds."
  type        = number
  default     = 600

  validation {
    condition     = contains([60, 120, 180, 240, 300, 600, 900, 1200, 1800, 2700, 3600], var.cloud_armor_ban_duration_sec)
    error_message = "The ban duration must be 60, 120, 180, 240, 300, 600, 900, 1200, 1800, 2700 or 3600 seconds."
  }
}

variable "enable_adaptive_protection" {
  description = "Enable Cloud Armor Adaptive Protection independently of policy attachment; review service tier and costs before enabling."
  type        = bool
  default     = false
}

# =============================================================================
# Monitoring & Alerting
# =============================================================================

variable "notification_channel_ids" {
  description = "Notification channel identifiers for LegendForge operational alerts."
  type        = list(string)
  default     = []
}

# =============================================================================
# Labels & Tags
# =============================================================================

variable "labels" {
  description = "Labels applied to LegendForge universal tabletop infrastructure resources."
  type        = map(string)
  default = {
    app         = "legendforge"
    environment = "production"
    managed_by  = "terraform"
    project     = "legendforge"
  }
}
