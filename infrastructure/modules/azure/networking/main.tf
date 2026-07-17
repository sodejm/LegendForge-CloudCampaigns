# =============================================================================
# infrastructure/modules/azure/networking/main.tf
# =============================================================================
# LegendForge Networking module configuration for universal tabletop infrastructure supporting multiple game systems.
# Supports LegendForge's universal tabletop platform across multiple game systems.
# =============================================================================

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
  tags     = var.tags
}

# Virtual Network with DDoS Protection
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = var.vnet_address_space

  dynamic "ddos_protection_plan" {
    for_each = var.enable_ddos_protection ? [1] : []
    content {
      id     = azurerm_ddos_protection_plan.main[0].id
      enable = true
    }
  }

  tags = var.tags
}

# DDoS Protection Plan (Standard)
resource "azurerm_ddos_protection_plan" "main" {
  count               = var.enable_ddos_protection ? 1 : 0
  name                = "ddos-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  tags = var.tags
}

# Public IP for NAT Gateway
resource "azurerm_public_ip" "nat" {
  count               = var.enable_nat_gateway ? 1 : 0
  name                = "pip-nat-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]

  tags = var.tags
}

# NAT Gateway for outbound connectivity
resource "azurerm_nat_gateway" "main" {
  count               = var.enable_nat_gateway ? 1 : 0
  name                = "natgw-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "Standard"

  tags = var.tags
}

# Associate NAT Gateway with Public IP
resource "azurerm_nat_gateway_public_ip_association" "main" {
  count          = var.enable_nat_gateway ? 1 : 0
  nat_gateway_id = azurerm_nat_gateway.main[0].id
  public_ip_id   = azurerm_public_ip.nat[0].id
}

# Subnets with Service Endpoints
resource "azurerm_subnet" "gateway" {
  name                                      = var.subnet_config.gateway.name
  resource_group_name                       = azurerm_resource_group.main.name
  virtual_network_name                      = azurerm_virtual_network.main.name
  address_prefixes                          = var.subnet_config.gateway.address_prefixes
  private_endpoint_network_policies_enabled = true
  service_endpoints                         = ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.Sql"]
}

resource "azurerm_subnet" "app" {
  name                                      = var.subnet_config.app.name
  resource_group_name                       = azurerm_resource_group.main.name
  virtual_network_name                      = azurerm_virtual_network.main.name
  address_prefixes                          = var.subnet_config.app.address_prefixes
  private_endpoint_network_policies_enabled = true
  service_endpoints                         = ["Microsoft.Storage", "Microsoft.KeyVault"]

  depends_on = [azurerm_nat_gateway_subnet_association.app]
}

resource "azurerm_subnet" "database" {
  name                                      = var.subnet_config.database.name
  resource_group_name                       = azurerm_resource_group.main.name
  virtual_network_name                      = azurerm_virtual_network.main.name
  address_prefixes                          = var.subnet_config.database.address_prefixes
  private_endpoint_network_policies_enabled = true
  service_endpoints                         = ["Microsoft.Sql"]
  delegation {
    name = "mysql-delegation"
    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"
    }
  }
}

resource "azurerm_subnet" "storage" {
  name                                      = var.subnet_config.storage.name
  resource_group_name                       = azurerm_resource_group.main.name
  virtual_network_name                      = azurerm_virtual_network.main.name
  address_prefixes                          = var.subnet_config.storage.address_prefixes
  private_endpoint_network_policies_enabled = true
  service_endpoints                         = ["Microsoft.Storage", "Microsoft.KeyVault"]
}

# Associate NAT Gateway with App Subnet
resource "azurerm_nat_gateway_subnet_association" "app" {
  count          = var.enable_nat_gateway ? 1 : 0
  subnet_id      = azurerm_subnet.app.id
  nat_gateway_id = azurerm_nat_gateway.main[0].id
}

# Network Security Groups

# Gateway NSG
resource "azurerm_network_security_group" "gateway" {
  name                = "nsg-${var.subnet_config.gateway.name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAppSubnet"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.subnet_config.app.address_prefixes[0]
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# App NSG
resource "azurerm_network_security_group" "app" {
  name                = "nsg-${var.subnet_config.app.name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowGateway"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.subnet_config.gateway.address_prefixes[0]
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowDatabase"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = "*"
    destination_address_prefix = var.subnet_config.database.address_prefixes[0]
  }

  security_rule {
    name                       = "AllowStorage"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = var.subnet_config.storage.address_prefixes[0]
  }

  security_rule {
    name                       = "AllowInternet"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  tags = var.tags
}

# Database NSG
resource "azurerm_network_security_group" "database" {
  name                = "nsg-${var.subnet_config.database.name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowAppSubnet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = var.subnet_config.app.address_prefixes[0]
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# Storage NSG
resource "azurerm_network_security_group" "storage" {
  name                = "nsg-${var.subnet_config.storage.name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowAppSubnet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.subnet_config.app.address_prefixes[0]
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# NSG Association
resource "azurerm_subnet_network_security_group_association" "gateway" {
  subnet_id                 = azurerm_subnet.gateway.id
  network_security_group_id = azurerm_network_security_group.gateway.id
}

resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app.id
}

resource "azurerm_subnet_network_security_group_association" "database" {
  subnet_id                 = azurerm_subnet.database.id
  network_security_group_id = azurerm_network_security_group.database.id
}

resource "azurerm_subnet_network_security_group_association" "storage" {
  subnet_id                 = azurerm_subnet.storage.id
  network_security_group_id = azurerm_network_security_group.storage.id
}
