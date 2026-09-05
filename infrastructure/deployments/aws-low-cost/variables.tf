variable "region" {
  description = "AWS region; change availability_zone to match."
  type        = string
  default     = "us-east-1"
}

variable "availability_zone" {
  description = "Fixed zone for both VM and retained volume."
  type        = string
  default     = "us-east-1a"
}

variable "instance_type" {
  description = "Burstable x86 instance. t3.small is the minimum-memory profile; t3.medium provides 4 GB."
  type        = string
  default     = "t3.small"
  validation {
    condition     = contains(["t3.small", "t3.medium", "t3.large", "t3.xlarge"], var.instance_type)
    error_message = "Choose a supported t3 size with at least 2 GB RAM."
  }
}

variable "name" {
  description = "Short resource name, also used for the GCP service account."
  type        = string
  default     = "legendforge-small"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,27}[a-z0-9]$", var.name))
    error_message = "Use 6 to 29 lowercase letters, digits, and hyphens; start with a letter and end with a letter or digit."
  }
}

variable "paused" {
  description = "Stop the VM while retaining its identity and disks. Complete first boot before setting true."
  type        = bool
  default     = false
}

variable "data_disk_gb" {
  description = "Independent persistent data disk size. Grow only; back up off-host."
  type        = number
  default     = 30
  validation {
    condition     = var.data_disk_gb >= 20 && floor(var.data_disk_gb) == var.data_disk_gb
    error_message = "Use a whole number of at least 20 GB."
  }
}

variable "app" {
  description = "Application inputs. Secrets remain in state and instance user data; protect both."
  type = object({
    hostname       = string
    foundry_image  = string
    tunnel_image   = string
    tunnel_token   = string
    license_key    = string
    admin_password = string
    username       = string
    password       = string
  })
  sensitive = true
}
