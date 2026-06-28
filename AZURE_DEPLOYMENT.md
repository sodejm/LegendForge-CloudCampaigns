# LegendForge - Azure Production Deployment Guide

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Setup Instructions](#setup-instructions)
4. [Deployment Steps](#deployment-steps)
5. [Configuration Details](#configuration-details)
6. [Monitoring & Alerts](#monitoring--alerts)
7. [Security Considerations](#security-considerations)
8. [Scaling & Performance](#scaling--performance)
9. [Disaster Recovery](#disaster-recovery)
10. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

### Component Overview

The deployment creates a highly available, scalable, and secure LegendForge infrastructure on Azure:

```
┌─────────────────────────────────────────────────────────┐
│                    Azure Portal                          │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │         Azure Front Door (CDN)                   │  │
│  │    Global Content Delivery Network              │  │
│  └────────────────────┬─────────────────────────────┘  │
│                       │                                  │
│  ┌────────────────────▼─────────────────────────────┐  │
│  │    Application Gateway / Load Balancer           │  │
│  │    (Port 80/443 → Backend 30000/30001)           │  │
│  └────────────────────┬─────────────────────────────┘  │
│                       │                                  │
│  ┌────────────────────▼─────────────────────────────┐  │
│  │   Virtual Network (10.0.0.0/16)                  │  │
│  │   ┌─────────────────────────────────────────┐   │  │
│  │   │  Gateway Subnet (10.0.1.0/24)           │   │  │
│  │   │    • NSG: HTTP/HTTPS only                │   │  │
│  │   └─────────────────────────────────────────┘   │  │
│  │   ┌─────────────────────────────────────────┐   │  │
│  │   │  App Subnet (10.0.2.0/23)               │   │  │
│  │   │    • VM Scale Set (2-10 instances)      │   │  │
│  │   │    • Private Endpoints                  │   │  │
│  │   │    • NSG: Restricted access             │   │  │
│  │   └─────────────────────────────────────────┘   │  │
│  │   ┌─────────────────────────────────────────┐   │  │
│  │   │  Database Subnet (10.0.4.0/24)          │   │  │
│  │   │    • MySQL/PostgreSQL Flexible Server   │   │  │
│  │   │    • High Availability (Zone Redundant) │   │  │
│  │   └─────────────────────────────────────────┘   │  │
│  │   ┌─────────────────────────────────────────┐   │  │
│  │   │  Storage Subnet (10.0.5.0/24)           │   │  │
│  │   │    • Private Endpoints                  │   │  │
│  │   │    • Blob Storage with Redundancy       │   │  │
│  │   └─────────────────────────────────────────┘   │  │
│  └─────────────────────────────────────────────────┘  │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │         Key Vault (Secrets & Certificates)       │  │
│  │    • Private Endpoint Access                     │  │
│  │    • RBAC Protected                              │  │
│  │    • Audit Logging                               │  │
│  └──────────────────────────────────────────────────┘  │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │   Monitoring & Logging                           │  │
│  │    • Log Analytics Workspace                     │  │
│  │    • Application Insights                        │  │
│  │    • Alert Rules & Dashboards                    │  │
│  └──────────────────────────────────────────────────┘  │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Key Services

1. **Azure Virtual Network**: Isolated network with DDoS protection
2. **VM Scale Sets**: Auto-scaling Foundry instances across availability zones
3. **Load Balancer**: Layer 4 load balancing with health checks
4. **Azure Database**: MySQL/PostgreSQL with automatic failover
5. **Azure Blob Storage**: GZRS redundant storage with CDN
6. **Key Vault**: Secrets management and certificate storage
7. **Log Analytics**: Centralized logging and monitoring
8. **Application Insights**: Application performance monitoring

### High Availability Features

- **Multi-zone deployment**: Resources spread across availability zones
- **Database replication**: Zone-redundant high availability
- **Geo-redundant storage**: Automatic cross-region replication
- **Auto-scaling**: Dynamic capacity based on CPU and memory
- **Health checks**: Automatic unhealthy instance replacement
- **Load balancing**: Even traffic distribution

---

## Prerequisites

### Required Tools

```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install Terraform
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Verify installations
az --version
terraform --version
```

### Azure Account Setup

```bash
# Login to Azure
az login

# Set default subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Create resource group for Terraform state
az group create --name rg-terraform-state --location eastus

# Create storage account for Terraform state
az storage account create \
  --resource-group rg-terraform-state \
  --name stgterraformstate \
  --sku Standard_LRS \
  --encryption-services blob

# Create container for state
az storage container create \
  --account-name stgterraformstate \
  --name tfstate
```

### Required Information

1. **Azure Subscription ID**
2. **Azure Tenant ID** (`az account show --query tenantId -o tsv`)
3. **Foundry VTT License Key** (from https://foundryvtt.com/me/account)
4. **SSH Public Key** for VM access
5. **Email address** for alerts

---

## Setup Instructions

### 1. Clone Repository

```bash
cd /Users/justinsoderberg/Development/LegendForge-CloudCampaigns
```

### 2. Generate SSH Key (if needed)

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/azure_foundry_key
cat ~/.ssh/azure_foundry_key.pub
```

### 3. Create terraform.tfvars

```bash
cd deployments/azure
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

**Important variables to set:**

- `foundry_license_key`: Your Foundry VTT license
- `database_password`: Strong password for database
- `vm_ssh_public_key`: Your SSH public key
- `alert_email`: Email for alerts
- `location`: Azure region (e.g., "eastus", "westus2")

### 4. Configure Remote State (Optional but Recommended)

```bash
# Create backend.tf
cat > backend.tf << 'BACKENDEOF'
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stgterraformstate"
    container_name       = "tfstate"
    key                  = "legendforge.tfstate"
  }
}
BACKENDEOF
```

---

## Deployment Steps

### 1. Initialize Terraform

```bash
terraform init

# If using remote state:
# terraform init -backend=true
```

### 2. Validate Configuration

```bash
terraform fmt -recursive ../..
terraform validate
```

### 3. Plan Deployment

```bash
terraform plan -out=tfplan

# Review the planned changes carefully
```

### 4. Apply Configuration

```bash
# Apply with auto-approval (use with caution)
terraform apply tfplan

# Save outputs
terraform output > deployment_outputs.json
```

### 5. Monitor Deployment Progress

```bash
# Watch resource creation
az group deployment list --resource-group rg-legendforge-prod

# Check VM Scale Set status
az vmss list-instances -g rg-legendforge-prod --vmss-name vmss-legendforge-prod
```

---

## Configuration Details

### Database Configuration

#### MySQL (Default)

```hcl
database_engine    = "mysql"
database_version   = "8.0"
database_sku_name  = "Standard_B2s"  # For production: D2s_v3 or higher
database_storage_size = 100  # GB
```

**Connection String:**

```
mysql -h <mysql-server-fqdn> -u azureadmin -p
```

#### PostgreSQL

```hcl
database_engine    = "postgres"
database_version   = "14"
database_sku_name  = "Standard_B2s"
database_storage_size = 100
```

### VM Configuration

```hcl
vm_size                = "Standard_D4s_v5"
scale_set_capacity     = 2      # Starting instances
scale_set_min_capacity = 2      # Minimum
scale_set_max_capacity = 10     # Maximum
```

**VM Size Recommendations:**

- **Dev/Test**: Standard_B2s (2 vCPU, 4 GB RAM)
- **Production**: Standard_D4s_v5 (4 vCPU, 16 GB RAM)
- **High Traffic**: Standard_D8s_v5 (8 vCPU, 32 GB RAM)

### Storage Configuration

```hcl
account_replication_type = "GZRS"  # Geo-Zone-Redundant
account_tier            = "Standard"
enable_cdn              = true
cdn_sku                 = "Standard_Microsoft"
```

**GZRS Replication:**

- Replicates data to 3 zones within primary region
- Replicates to secondary region
- 99.99999999999999% durability (16 nines)

---

## Monitoring & Alerts

### Access Monitoring Dashboard

```bash
# Get dashboard URL
az portal show --name dashboard-legendforge-prod

# View logs
az monitor log-analytics workspace show \
  --resource-group rg-legendforge-prod \
  --workspace-name law-legendforge-prod
```

### Alert Rules Created

1. **High CPU Usage** (>80%): Scale set, Database
2. **Low Available Memory** (<512MB): Scale set
3. **Database CPU** (>85%): Database server
4. **Storage Quota** (>80%): Storage account

### Check Alert Status

```bash
# List alert rules
az monitor metrics alert list --resource-group rg-legendforge-prod

# View alert history
az monitor alert list-instances --resource-group rg-legendforge-prod
```

### Application Insights Queries

**Track Foundry API Performance:**

```kusto
requests
| where url contains "/api/"
| summarize avg(duration), count() by url
| top 20 by count_
```

**Monitor Errors:**

```kusto
exceptions
| where timestamp > ago(1d)
| summarize count() by problemId
```

---

## Security Considerations

### Network Security

✅ **Implemented:**

- Network Security Groups (NSGs) with restrictive rules
- Private endpoints for Key Vault and Storage
- NAT Gateway for outbound connections
- DDoS Protection Standard

📋 **Additional Recommendations:**

```bash
# Enable Azure Defender
az security auto-provisioning-setting update \
  --auto-provision "On" \
  --auto-provision-setting-name "default"

# Configure firewall rules
az sql server firewall-rule create \
  --name AllowAppSubnet \
  --server myserver \
  --resource-group mygroup \
  --start-ip-address 10.0.2.0 \
  --end-ip-address 10.0.3.255
```

### Identity & Access Management

✅ **Implemented:**

- Azure RBAC for all resources
- Managed Identity for VMs
- Key Vault access policies
- Service principal authentication

📋 **RBAC Best Practices:**

```bash
# Assign roles to team members
az role assignment create \
  --assignee user@example.com \
  --role "Contributor" \
  --resource-group rg-legendforge-prod

# Audit access
az monitor activity-log list \
  --resource-group rg-legendforge-prod \
  --offset 7d
```

### Secrets Management

✅ **Implemented:**

- All secrets stored in Key Vault
- Purge protection enabled
- Audit logging enabled
- Private endpoint access

📋 **Rotate Secrets:**

```bash
# Update database password
az mysql flexible-server update \
  --name mysql-legendforge-prod \
  --admin-password newpassword \
  --resource-group rg-legendforge-prod

# Update Key Vault secret
az keyvault secret set \
  --vault-name kv-legendforge-abc123 \
  --name database-password \
  --value newpassword
```

### SSL/TLS Configuration

```bash
# Import certificate to Key Vault
az keyvault certificate import \
  --vault-name kv-legendforge-abc123 \
  --name foundry-cert \
  --file /path/to/certificate.pfx

# Configure Application Gateway with HTTPS
# See: deployments/azure/appgateway.tf
```

---

## Scaling & Performance

### Auto-Scaling Policies

**CPU-Based:**

- Scale up when CPU > 75% for 5 minutes
- Scale down when CPU < 25% for 5 minutes
- Maximum increase: 1 instance per 5 minutes

**Memory-Based:**

- Scale up when available memory < 512MB
- Maximum capacity: 10 instances

### Manual Scaling

```bash
# Get scale set info
az vmss show \
  --name vmss-legendforge-prod \
  --resource-group rg-legendforge-prod

# Scale to specific capacity
az vmss scale \
  --name vmss-legendforge-prod \
  --resource-group rg-legendforge-prod \
  --new-capacity 5

# Update scaling policies
terraform apply -var="scale_set_max_capacity=20"
```

### Performance Tuning

```bash
# Database connection pooling
# MySQL configuration in database/main.tf:
- max_connections = 500
- innodb_buffer_pool_size = 805306368

# CDN optimization
# Enable compression
az cdn endpoint update \
  --profile-name cdn-legendforge-prod \
  --name cdn-media-legendforge \
  --resource-group rg-legendforge-prod \
  --enable-compression true
```

### Monitoring Performance

```bash
# Get scale set metrics
az monitor metrics list-definitions \
  --resource /subscriptions/.../resourceGroups/rg-legendforge-prod/providers/Microsoft.Compute/virtualMachineScaleSets/vmss-legendforge-prod

# Retrieve performance data
az monitor metrics list \
  --resource /subscriptions/.../resourceGroups/rg-legendforge-prod/providers/Microsoft.Compute/virtualMachineScaleSets/vmss-legendforge-prod \
  --metric "Percentage CPU" \
  --start-time 2024-06-01T00:00:00Z \
  --interval PT5M
```

---

## Disaster Recovery

### Backup Strategy

✅ **Implemented:**

- Database automated backups (35 days retention)
- Geo-redundant storage (GZRS)
- VM scale set snapshots
- Application data in blob storage

### Backup & Recovery Commands

```bash
# Database backup status
az mysql flexible-server backup list \
  --resource-group rg-legendforge-prod \
  --server-name mysql-legendforge-prod

# List storage backups
az storage blob list \
  --account-name stgdnd... \
  --container-name foundry-backups

# Restore database from backup
az mysql flexible-server restore \
  --resource-group rg-legendforge-prod \
  --name mysql-legendforge-restored \
  --source-server mysql-legendforge-prod \
  --restore-point-in-time "2024-06-28T10:00:00"

# Restore from storage backup
az storage blob download \
  --account-name stgdnd... \
  --container-name foundry-backups \
  --name backup.tar.gz \
  --file /local/path/backup.tar.gz
```

### Site Recovery Plan

1. **Database Failure**: Automatic failover to standby (built-in)
2. **VM Failure**: Auto-healing via scale set
3. **Storage Failure**: Geo-redundant copy available
4. **Regional Outage**: Consider Azure Traffic Manager

---

## Troubleshooting

### Common Issues

#### 1. VM Scale Set Not Scaling

```bash
# Check autoscale settings
az monitor autoscale-settings list \
  --resource-group rg-legendforge-prod

# View autoscale history
az monitor autoscale-settings show \
  --resource-group rg-legendforge-prod \
  --name autoscale-cpu-legendforge \
  --query "profiles[0].rules"

# Manually test scaling
az vmss scale \
  --name vmss-legendforge-prod \
  --resource-group rg-legendforge-prod \
  --new-capacity 3
```

#### 2. Database Connection Issues

```bash
# Check firewall rules
az mysql flexible-server firewall-rule list \
  --resource-group rg-legendforge-prod \
  --server-name mysql-legendforge-prod

# Test connectivity
mysql -h mysql-legendforge-prod.mysql.database.azure.com \
  -u azureadmin \
  -p \
  -e "SELECT 1"

# Check NSG rules
az network nsg rule list \
  --resource-group rg-legendforge-prod \
  --nsg-name nsg-snet-database
```

#### 3. Storage Access Issues

```bash
# Check storage account firewall
az storage account network-rule list \
  --account-name stgdnd... \
  --resource-group rg-legendforge-prod

# Verify RBAC permissions
az role assignment list \
  --resource-group rg-legendforge-prod

# Test storage access
az storage blob list \
  --account-name stgdnd... \
  --container-name foundry-data
```

#### 4. DNS Resolution Issues

```bash
# Check private DNS zones
az network private-dns zone list \
  --resource-group rg-legendforge-prod

# Verify A records
az network private-dns record-set a list \
  --resource-group rg-legendforge-prod \
  --zone-name privatelink.blob.core.windows.net

# Flush local DNS cache
sudo systemd-resolve --flush-caches
```

### Viewing Logs

```bash
# Application logs
az monitor log-analytics query \
  --workspace-name law-legendforge-prod \
  --analytics-query "AzureDiagnostics | limit 100"

# VM system logs
az vm boot-diagnostics get-boot-log \
  --name vmss-legendforge-prod \
  --resource-group rg-legendforge-prod

# Application Insights traces
az monitor app-insights query \
  --app ai-legendforge-prod \
  --resource-group rg-legendforge-prod \
  --analytics-query "traces | limit 100"
```

### Debug Commands

```bash
# SSH into scale set VM
az vmss list-instances -g rg-legendforge-prod --vmss-name vmss-legendforge-prod
az vmss run-command invoke \
  --resource-group rg-legendforge-prod \
  --name vmss-legendforge-prod \
  --command-id RunShellScript \
  --scripts "docker logs foundry"

# Check resource creation status
az deployment group list \
  --resource-group rg-legendforge-prod \
  --query "[*].[name, properties.provisioningState]"
```

---

## Post-Deployment Steps

### 1. Configure Foundry

Access Foundry at the load balancer IP:

```
http://<load-balancer-public-ip>
```

### 2. Setup SSL/TLS

```bash
# Generate self-signed certificate (for testing)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /tmp/foundry.key -out /tmp/foundry.crt

# Import to Key Vault
az keyvault certificate import \
  --vault-name kv-legendforge-abc123 \
  --name foundry-cert \
  --file /tmp/foundry.pfx
```

### 3. Configure Backup Schedule

```bash
# Automated daily backup at 2 AM
az vm create ... --data-disk-sizes-gb 100
# Backup configured via terraform module
```

### 4. Test Failover

```bash
# Simulate VM failure
az vmss reimage --instance-ids 0 \
  --resource-group rg-legendforge-prod \
  --vmss-name vmss-legendforge-prod

# Monitor recovery
watch -n 5 "az vmss list-instances -g rg-legendforge-prod --vmss-name vmss-legendforge-prod --query '[*].[instanceId, provisioningState]'"
```

---

## Cost Optimization

### Estimate Costs

```bash
terraform plan -json | jq '.resource_changes[] | select(.change=="create") | .address'
```

### Cost Reduction Tips

1. **Use reserved instances**: ~30% discount
2. **Reduce VM size for dev**: Standard_B2s instead of D4s
3. **Enable spot instances**: ~70% discount (for non-critical workloads)
4. **Set database retention**: Reduce backup retention days
5. **Optimize storage**: Clean up old backups

---

## Cleanup

### Destroy Infrastructure

```bash
# Show what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy

# Verify deletion
az group delete --name rg-legendforge-prod --yes
```

### Preserve Data Before Deletion

```bash
# Backup database
az mysql flexible-server backup create \
  --resource-group rg-legendforge-prod \
  --server-name mysql-legendforge-prod \
  --backup-name final-backup

# Export storage data
az storage blob download-batch \
  --account-name stgdnd... \
  --source foundry-data \
  --destination /local/backup
```

---

## Support & Resources

- **Azure Documentation**: https://docs.microsoft.com/azure/
- **Terraform Registry**: https://registry.terraform.io/
- **Foundry VTT Docs**: https://foundryvtt.com/article/installation/
- **Azure CLI Reference**: https://docs.microsoft.com/cli/azure/reference-index

---

## Version History

- **v1.0** (2024-06-28): Initial production deployment guide
  - Azure VMs with Scale Sets
  - MySQL/PostgreSQL databases
  - Blob storage with CDN
  - Key Vault and RBAC
  - Log Analytics and Application Insights

---

## License

This infrastructure code is provided as-is for deployment of LegendForge.
LegendForge is licensed separately - see https://foundryvtt.com/
