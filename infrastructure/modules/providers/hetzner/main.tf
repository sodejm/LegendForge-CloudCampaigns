# =============================================================================
# infrastructure/modules/providers/hetzner/main.tf
# =============================================================================
# LegendForge Hetzner provider configuration for cost-efficient universal tabletop infrastructure.
# Supports LegendForge's universal tabletop platform across multiple game systems.

terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.40"
    }
  }
}

# Data source: Latest Ubuntu 22.04 LTS image
data "hcloud_image" "ubuntu" {
  name = "ubuntu-22.04"
}

# ===== Network =====
resource "hcloud_network" "foundry" {
  name = "${var.project_name}-${var.environment}-network"
}

resource "hcloud_network_subnet" "foundry" {
  network_id   = hcloud_network.foundry.id
  type         = "cloud"
  network_zone = var.network_zone
  ip_range     = var.subnet_cidr
}

# ===== Firewall =====
resource "hcloud_firewall" "foundry" {
  name = "${var.project_name}-${var.environment}-fw"

  # Ingress: SSH break-glass (optional)
  dynamic "rule" {
    for_each = var.admin_ssh_cidr != null ? [1] : []
    content {
      direction = "in"
      port      = "22"
      protocol  = "tcp"
      source {
        cidr = var.admin_ssh_cidr
      }
    }
  }

  # Egress: Allow all (implicit in Hetzner)
  rule {
    direction = "out"
    port      = "any"
    protocol  = "esp"
    destination {
      cidr = "0.0.0.0/0"
    }
  }

  labels = {
    project = var.project_name
    env     = var.environment
  }
}

# ===== Server =====
resource "hcloud_server" "foundry" {
  count       = var.compute_enabled ? 1 : 0
  name        = "${var.project_name}-${var.environment}-server"
  image       = data.hcloud_image.ubuntu.id
  server_type = var.server_type
  datacenter  = var.datacenter
  automount   = false
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  labels = {
    project = var.project_name
    env     = var.environment
  }

  user_data = base64encode(module.foundry_app.user_data)

  depends_on = [hcloud_network_subnet.foundry]
}

# ===== Volume (Persistent Data) =====
resource "hcloud_volume" "foundry_data" {
  count             = var.compute_enabled ? 1 : 0
  name              = "${var.project_name}-${var.environment}-data-volume"
  size              = var.data_volume_size_gb
  server_id         = hcloud_server.foundry[0].id
  automount         = false
  format            = "ext4"
  linux_device_name = "/dev/disk/by-id/scsi-0HC_Volume_${hcloud_volume.foundry_data[0].id}"

  labels = {
    project = var.project_name
    env     = var.environment
  }
}

# ===== Server Attachment to Network =====
resource "hcloud_server_network" "foundry" {
  count      = var.compute_enabled ? 1 : 0
  server_id  = hcloud_server.foundry[0].id
  network_id = hcloud_network.foundry.id
  ip         = "10.0.0.2"
}

# ===== Firewall Attachment =====
resource "hcloud_firewall_attachment" "foundry" {
  firewall_id = hcloud_firewall.foundry.id
  server_ids  = var.compute_enabled ? [hcloud_server.foundry[0].id] : []
}

# ===== LegendForge Application Module =====
module "foundry_app" {
  source = "../../foundry-app"

  foundry_hostname        = var.foundry_hostname
  data_device             = var.compute_enabled ? "/dev/disk/by-id/scsi-0HC_Volume_${hcloud_volume.foundry_data[0].id}" : "/dev/null"
  data_mount_path         = var.data_mount_path
  data_volume_fs_label    = var.data_volume_fs_label
  foundry_image           = var.foundry_image
  cloudflared_image       = var.cloudflared_image
  timezone                = var.timezone
  foundry_username        = var.foundry_username
  foundry_password        = var.foundry_password
  foundry_release_url     = var.foundry_release_url
  foundry_license_key     = var.foundry_license_key
  foundry_admin_key       = var.foundry_admin_key
  cloudflare_tunnel_token = var.cloudflare_tunnel_token
}
