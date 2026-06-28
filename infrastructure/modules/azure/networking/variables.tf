# =============================================================================
# infrastructure/modules/azure/networking/variables.tf
# =============================================================================
# LegendForge Networking variable definitions for universal tabletop infrastructure supporting multiple game systems.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# =============================================================================

variable "environment" {
  description = "LegendForge deployment environment (dev, staging, prod) used to scope multi-system infrastructure resources."
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "location" {
  description = "Azure region where LegendForge's multi-system tabletop infrastructure is deployed."
  type        = string
  default     = "eastus"
}

variable "project_name" {
  description = "LegendForge project slug used for consistent naming across universal tabletop infrastructure resources."
  type        = string
  default     = "legendforge"
}

variable "vnet_address_space" {
  description = "Address space for virtual network for LegendForge's universal tabletop infrastructure."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_config" {
  description = "Subnet configuration for LegendForge's universal tabletop infrastructure."
  type = object({
    gateway = object({
      name             = string
      address_prefixes = list(string)
    })
    app = object({
      name             = string
      address_prefixes = list(string)
    })
    database = object({
      name             = string
      address_prefixes = list(string)
    })
    storage = object({
      name             = string
      address_prefixes = list(string)
    })
  })
  default = {
    gateway = {
      name             = "snet-gateway"
      address_prefixes = ["10.0.1.0/24"]
    }
    app = {
      name             = "snet-app"
      address_prefixes = ["10.0.2.0/23"]
    }
    database = {
      name             = "snet-database"
      address_prefixes = ["10.0.4.0/24"]
    }
    storage = {
      name             = "snet-storage"
      address_prefixes = ["10.0.5.0/24"]
    }
  }
}

variable "enable_nat_gateway" {
  description = "Whether to enable nat gateway for LegendForge's universal tabletop platform."
  type        = bool
  default     = true
}

variable "enable_ddos_protection" {
  description = "Whether to enable ddos protection for LegendForge's universal tabletop platform."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Metadata tags applied to LegendForge universal tabletop infrastructure resources."
  type        = map(string)
  default = {
    Project     = "D&D Foundry"
    ManagedBy   = "Terraform"
    CreatedDate = "2024"
  }
}
