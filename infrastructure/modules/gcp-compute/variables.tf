# =============================================================================
# infrastructure/modules/gcp-compute/variables.tf
# =============================================================================
# LegendForge GCP Compute variable definitions for universal tabletop infrastructure supporting multiple game systems.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# =============================================================================

variable "project_name" {
  description = "LegendForge project slug used for consistent naming across universal tabletop infrastructure resources."
  type        = string
}

variable "primary_region" {
  description = "Primary region for LegendForge production traffic and stateful services."
  type        = string
  default     = "us-central1"
}

variable "machine_type" {
  description = "Compute machine type used for LegendForge platform services."
  type        = string
  default     = "n2-standard-2" # 2 vCPU, 8GB RAM - good for small/medium Foundry
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
  description = "Minimum number of instances for LegendForge's universal tabletop infrastructure."
  type        = number
  default     = 2
}

variable "max_instances" {
  description = "Maximum number of instances for LegendForge's universal tabletop infrastructure."
  type        = number
  default     = 5
}

variable "cpu_target_utilization" {
  description = "Target CPU utilization for autoscaling (0.0-1.0) for LegendForge's universal tabletop infrastructure."
  type        = number
  default     = 0.7
}

variable "enable_memory_autoscaling" {
  description = "Whether to enable memory autoscaling for LegendForge's universal tabletop platform."
  type        = bool
  default     = false
}

variable "memory_target_utilization" {
  description = "Target memory utilization for autoscaling (0.0-1.0) for LegendForge's universal tabletop infrastructure."
  type        = number
  default     = 0.8
}

variable "foundry_compute_sa_email" {
  description = "Service account email for instances for LegendForge's universal tabletop infrastructure."
  type        = string
}

variable "vpc_network_name" {
  description = "Resource name used by LegendForge infrastructure for vpc network name."
  type        = string
}

variable "subnet_name" {
  description = "Resource name used by LegendForge infrastructure for subnet name."
  type        = string
}

variable "kms_key_id" {
  description = "Provider resource ID used by LegendForge infrastructure for kms key id."
  type        = string
  default     = ""
}

variable "startup_script" {
  description = "Startup script (cloud-init) for instances for LegendForge's universal tabletop infrastructure."
  type        = string
}

variable "labels" {
  description = "Labels applied to LegendForge universal tabletop infrastructure resources."
  type        = map(string)
  default = {
    app         = "legendforge"
    environment = "production"
    managed_by  = "terraform"
  }
}
