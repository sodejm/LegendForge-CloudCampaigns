# =============================================================================
# infrastructure/modules/azure/compute/main.tf
# =============================================================================
# LegendForge Compute module configuration for universal tabletop infrastructure supporting multiple game systems.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# =============================================================================

# Managed Identity for VMs
resource "azurerm_user_assigned_identity" "vmss" {
  name                = "mid-${var.project_name}-vmss"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Public IP for Load Balancer
resource "azurerm_public_ip" "lb" {
  name                = "pip-lb-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}

# Load Balancer
resource "azurerm_lb" "main" {
  name                = "lb-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  sku_tier            = "Regional"

  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.lb.id
  }

  tags = var.tags
}

# Backend Address Pool
resource "azurerm_lb_backend_address_pool" "main" {
  name            = "backend-pool"
  loadbalancer_id = azurerm_lb.main.id
}

# Load Balancer Rule for HTTP
resource "azurerm_lb_rule" "http" {
  name                           = "rule-http"
  loadbalancer_id                = azurerm_lb.main.id
  frontend_ip_configuration_name = "frontend-ip"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main.id]
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 30000
  probe_id                       = azurerm_lb_probe.http.id
  enable_floating_ip             = false
}

# Load Balancer Rule for HTTPS
resource "azurerm_lb_rule" "https" {
  name                           = "rule-https"
  loadbalancer_id                = azurerm_lb.main.id
  frontend_ip_configuration_name = "frontend-ip"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main.id]
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 30001
  probe_id                       = azurerm_lb_probe.https.id
  enable_floating_ip             = false
}

# Health Probes
resource "azurerm_lb_probe" "http" {
  name            = "probe-http"
  loadbalancer_id = azurerm_lb.main.id
  protocol        = "Http"
  port            = 30000
  request_path    = "/api/health"
  interval_in_seconds = 15
  number_of_probes    = 3
}

resource "azurerm_lb_probe" "https" {
  name            = "probe-https"
  loadbalancer_id = azurerm_lb.main.id
  protocol        = "Https"
  port            = 30001
  request_path    = "/api/health"
  interval_in_seconds = 15
  number_of_probes    = 3
}

# Custom data script for LegendForge installation
locals {
  custom_data = base64encode(templatefile("${path.module}/scripts/foundry-init.sh", {
    foundry_version      = var.foundry_version
    foundry_license_key  = var.foundry_license_key
    database_host        = var.database_host
    database_name        = var.database_name
    storage_account_name = var.storage_account_name
    storage_account_key  = var.storage_account_key
    key_vault_uri        = var.key_vault_uri
  }))
}

# Virtual Machine Scale Set
resource "azurerm_linux_virtual_machine_scale_set" "main" {
  name                            = "vmss-${var.project_name}-${var.environment}"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  sku                             = var.vm_size
  instances                       = var.scale_set_capacity
  admin_username                  = var.admin_username
  overprovision                   = false
  health_probe_id                 = azurerm_lb_probe.http.id
  upgrade_mode                    = "Rolling"
  zone_balance                    = true
  zones                           = ["1", "2", "3"]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    storage_account_type = "Premium_LRS"
    caching              = "ReadWrite"
    disk_size_gb         = 128
  }

  source_image_reference {
    publisher = var.os_image.publisher
    offer     = var.os_image.offer
    sku       = var.os_image.sku
    version   = var.os_image.version
  }

  network_interface {
    name                      = "nic"
    primary                   = true
    network_security_group_id = var.app_nsg_id

    ip_configuration {
      name                                   = "ipconfig"
      primary                                = true
      subnet_id                              = var.app_subnet_id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.main.id]
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.vmss.id]
  }

  custom_data = local.custom_data

  rolling_upgrade_policy {
    max_batch_instance_percent              = 30
    max_unhealthy_instance_percent          = 30
    max_unhealthy_upgraded_instance_percent = 30
    pause_time_between_batches              = "PT30S"
  }

  tags = var.tags

  depends_on = [azurerm_lb_rule.http, azurerm_lb_rule.https]
}

# Auto-scaling policy for CPU
resource "azurerm_monitor_autoscale_setting" "cpu" {
  name                = "autoscale-cpu-${var.project_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.main.id

  profile {
    name = "default"

    capacity {
      default = var.scale_set_capacity
      minimum = var.scale_set_min_capacity
      maximum = var.scale_set_max_capacity
    }

    rule {
      metric_trigger {
        metric_name              = "Percentage CPU"
        metric_resource_id       = azurerm_linux_virtual_machine_scale_set.main.id
        time_grain               = "PT1M"
        statistic                = "Average"
        time_window              = "PT5M"
        time_aggregation         = "Average"
        operator                 = "GreaterThan"
        threshold                = 75
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name              = "Percentage CPU"
        metric_resource_id       = azurerm_linux_virtual_machine_scale_set.main.id
        time_grain               = "PT1M"
        statistic                = "Average"
        time_window              = "PT5M"
        time_aggregation         = "Average"
        operator                 = "LessThan"
        threshold                = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }
}

# Auto-scaling policy for memory
resource "azurerm_monitor_autoscale_setting" "memory" {
  name                = "autoscale-memory-${var.project_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.main.id

  profile {
    name = "memory-based"

    capacity {
      default = var.scale_set_capacity
      minimum = var.scale_set_min_capacity
      maximum = var.scale_set_max_capacity
    }

    rule {
      metric_trigger {
        metric_name              = "Available Memory Bytes"
        metric_resource_id       = azurerm_linux_virtual_machine_scale_set.main.id
        time_grain               = "PT1M"
        statistic                = "Average"
        time_window              = "PT5M"
        time_aggregation         = "Average"
        operator                 = "LessThan"
        threshold                = 536870912 # 512MB
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }
}
