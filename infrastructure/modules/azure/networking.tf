# =============================================================================
# Azure Networking — VNet, Subnets, NSGs, Network Interfaces
# =============================================================================

# ===== Virtual Network =====
resource "azurerm_virtual_network" "main" {
  name                = "${local.name_prefix}-vnet"
  address_space       = [local.vnet_cidr]
  location            = var.azure_region
  resource_group_name = var.resource_group_name

  tags = local.common_tags
}

# ===== Subnet for Foundry Compute =====
resource "azurerm_subnet" "compute" {
  name                 = "${local.name_prefix}-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.subnet_cidr]

  service_endpoints = [
    "Microsoft.KeyVault",
    "Microsoft.Storage",
    "Microsoft.Sql"
  ]
}

# ===== Bastion Subnet (if Bastion is enabled) =====
resource "azurerm_subnet" "bastion" {
  count                = var.enable_bastion ? 1 : 0
  name                 = "AzureBastionSubnet"  # Must be exactly this name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.bastion_subnet_cidr]
}

# ===== Network Security Group: Foundry Compute =====
resource "azurerm_network_security_group" "compute" {
  name                = "${local.name_prefix}-nsg"
  location            = var.azure_region
  resource_group_name = var.resource_group_name

  # Outbound: Allow all (for Cloudflare Tunnel and updates)
  security_rule {
    name                       = "AllowAllOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Inbound: SSH break-glass (optional)
  dynamic "security_rule" {
    for_each = var.allow_ssh_cidr != null ? [1] : []
    content {
      name                       = "AllowSSHBreakGlass"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = var.allow_ssh_cidr
      destination_address_prefix = "*"
    }
  }

  # Inbound: Deny all else (default allow rule still needed, though)
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

# ===== NSG Association with Compute Subnet =====
resource "azurerm_subnet_network_security_group_association" "compute" {
  subnet_id                 = azurerm_subnet.compute.id
  network_security_group_id = azurerm_network_security_group.compute.id
}

# ===== Network Security Group: Bastion =====
resource "azurerm_network_security_group" "bastion" {
  count               = var.enable_bastion ? 1 : 0
  name                = "${local.name_prefix}-bastion-nsg"
  location            = var.azure_region
  resource_group_name = var.resource_group_name

  # Inbound: HTTPS from internet (Bastion traffic)
  security_rule {
    name                       = "AllowHttpsInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  # Inbound: Gateway Manager
  security_rule {
    name                       = "AllowGatewayManagerInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  # Outbound: SSH and RDP to VNet
  security_rule {
    name                       = "AllowSshRdpOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "22,3389"
    source_address_prefix      = "*"
    destination_address_prefix = local.vnet_cidr
  }

  # Outbound: HTTPS to Azure
  security_rule {
    name                       = "AllowAzureCloudOutbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureCloud"
  }

  tags = local.common_tags
}

# ===== NSG Association with Bastion Subnet =====
resource "azurerm_subnet_network_security_group_association" "bastion" {
  count                     = var.enable_bastion ? 1 : 0
  subnet_id                 = azurerm_subnet.bastion[0].id
  network_security_group_id = azurerm_network_security_group.bastion[0].id
}

# ===== Public IP for Bastion =====
resource "azurerm_public_ip" "bastion" {
  count               = var.enable_bastion ? 1 : 0
  name                = "${local.name_prefix}-bastion-pip"
  location            = var.azure_region
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.common_tags
}

# ===== Azure Bastion Host =====
resource "azurerm_bastion_host" "main" {
  count               = var.enable_bastion ? 1 : 0
  name                = "${local.name_prefix}-bastion"
  location            = var.azure_region
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion[0].id
    public_ip_address_id = azurerm_public_ip.bastion[0].id
  }

  tags = local.common_tags
}

# ===== Public IP for VM (if needed) =====
resource "azurerm_public_ip" "vm" {
  count               = var.compute_enabled ? 1 : 0
  name                = "${local.name_prefix}-pip"
  location            = var.azure_region
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.common_tags
}

# ===== Network Interface =====
resource "azurerm_network_interface" "compute" {
  count               = var.compute_enabled ? 1 : 0
  name                = "${local.name_prefix}-nic"
  location            = var.azure_region
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.compute.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.compute_enabled ? azurerm_public_ip.vm[0].id : null
  }

  tags = local.common_tags
}

# ===== Network Interface - NSG Association =====
resource "azurerm_network_interface_security_group_association" "compute" {
  count                     = var.compute_enabled ? 1 : 0
  network_interface_id      = azurerm_network_interface.compute[0].id
  network_security_group_id = azurerm_network_security_group.compute.id
}

# ===== Network Watcher Flow Logs (if monitoring enabled) =====
resource "azurerm_network_watcher" "main" {
  count               = var.enable_monitoring ? 1 : 0
  name                = "${local.name_prefix}-nw"
  location            = var.azure_region
  resource_group_name = var.resource_group_name

  tags = local.common_tags
}

resource "azurerm_network_watcher_flow_log" "main" {
  count                     = var.enable_monitoring ? 1 : 0
  network_watcher_name      = azurerm_network_watcher.main[0].name
  resource_group_name       = var.resource_group_name
  name                      = "${local.name_prefix}-flow-logs"
  network_security_group_id = azurerm_network_security_group.compute.id
  storage_account_id        = azurerm_storage_account.flowlogs[0].id
  enabled                   = true

  traffic_analytics {
    enabled = true
    workspace_id = azurerm_log_analytics_workspace.main[0].workspace_id
    workspace_region = var.azure_region
    workspace_resource_id = azurerm_log_analytics_workspace.main[0].id
  }

  retention_policy {
    enabled = true
    days    = 30
  }
}

# ===== Storage Account for Flow Logs =====
resource "azurerm_storage_account" "flowlogs" {
  count                    = var.enable_monitoring ? 1 : 0
  name                     = "${replace(local.name_prefix, "-", "")}flowlogs"  # No hyphens
  location                 = var.azure_region
  resource_group_name      = var.resource_group_name
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = local.common_tags
}

# ===== Log Analytics Workspace =====
resource "azurerm_log_analytics_workspace" "main" {
  count               = var.enable_monitoring ? 1 : 0
  name                = "${local.name_prefix}-law"
  location            = var.azure_region
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.common_tags
}
