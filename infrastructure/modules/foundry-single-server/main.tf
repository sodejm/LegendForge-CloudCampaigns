terraform {
  required_version = ">= 1.7.0"
}

variable "device" {
  description = "Stable provider-specific by-id path of the independent data disk."
  type        = string
  validation {
    condition     = can(regex("^/dev/disk/by-id/[A-Za-z0-9_-]+$", var.device))
    error_message = "Use an explicit /dev/disk/by-id device, without shell metacharacters."
  }
}

variable "app" {
  description = "Pinned container images, public hostname, and private application credentials. Stored in Terraform state and instance user data."
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
  validation {
    condition = alltrue([
      for image in [var.app.foundry_image, var.app.tunnel_image] :
      can(regex("(:[0-9][A-Za-z0-9._-]*|@sha256:[a-f0-9]{64})$", image))
    ])
    error_message = "Pin both images to an explicit numeric version tag or sha256 digest."
  }
}

locals {
  compose = jsonencode({
    services = {
      foundry = {
        image    = var.app.foundry_image
        hostname = "legendforge-foundry"
        user     = "1000:1000"
        restart  = "no"
        volumes  = ["/srv/foundry-data:/data"]
        environment = {
          FOUNDRY_HOSTNAME     = var.app.hostname
          FOUNDRY_PROXY_PORT   = "443"
          FOUNDRY_PROXY_SSL    = "true"
          FOUNDRY_IP_DISCOVERY = "false"
          FOUNDRY_LOG_SIZE     = "10m"
          FOUNDRY_MAX_LOGS     = "3"
        }
        secrets = [{ source = "foundry_config", target = "config.json" }]
        logging = { driver = "json-file", options = { max-size = "10m", max-file = "3" } }
      }
      tunnel = {
        image      = var.app.tunnel_image
        restart    = "no"
        command    = ["tunnel", "--no-autoupdate", "run", "--token-file", "/run/secrets/tunnel_token"]
        secrets    = ["tunnel_token"]
        depends_on = ["foundry"]
        logging    = { driver = "json-file", options = { max-size = "10m", max-file = "3" } }
      }
    }
    secrets = {
      foundry_config = { file = "/opt/legendforge/foundry.json" }
      tunnel_token   = { file = "/opt/legendforge/tunnel-token" }
    }
  })
  files = [
    { path = "/opt/legendforge/compose.json", permissions = "0600", content = local.compose },
    { path = "/opt/legendforge/foundry.json", permissions = "0444", content = jsonencode({
      foundry_admin_key   = var.app.admin_password
      foundry_license_key = var.app.license_key
      foundry_username    = var.app.username
      foundry_password    = var.app.password
    }) },
    { path = "/opt/legendforge/tunnel-token", permissions = "0444", content = var.app.tunnel_token },
    { path = "/usr/local/sbin/legendforge-prepare-data", permissions = "0755", content = file("${path.module}/prepare-data.py") },
    { path = "/etc/systemd/system/legendforge.service", permissions = "0644", content = <<-UNIT
      [Unit]
      Description=LegendForge Foundry and Cloudflare Tunnel
      Requires=docker.service
      After=docker.service network-online.target
      Wants=network-online.target
      StartLimitIntervalSec=0

      [Service]
      Type=simple
      WorkingDirectory=/opt/legendforge
      ExecStartPre=/usr/local/sbin/legendforge-prepare-data ${var.device} /srv/foundry-data
      ExecStart=/usr/bin/docker compose -f compose.json up --abort-on-container-exit
      ExecStop=/usr/bin/docker compose -f compose.json down --timeout 60
      Restart=always
      RestartSec=30
      TimeoutStartSec=360
      TimeoutStopSec=90

      [Install]
      WantedBy=multi-user.target
    UNIT
    }
  ]
}

output "user_data" {
  description = "Raw cloud-config; the caller uses the provider's unencoded user-data field."
  sensitive   = true
  value = "#cloud-config\n${yamlencode({
    package_update = true
    packages       = ["docker.io", "docker-compose-v2", "python3"]
    bootcmd        = [["mkdir", "-p", "/opt/legendforge"], ["chmod", "0700", "/opt/legendforge"]]
    write_files    = [for f in local.files : merge(f, { encoding = "b64", content = base64encode(f.content) })]
    runcmd         = [["systemctl", "enable", "--now", "docker"], ["systemctl", "daemon-reload"], ["systemctl", "enable", "--now", "legendforge"]]
  })}"
}
