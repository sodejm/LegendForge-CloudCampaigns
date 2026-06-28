# LegendForge - Azure Infrastructure

This directory contains production-ready Terraform infrastructure for deploying LegendForge on Microsoft Azure with full high availability, security, monitoring, and disaster recovery.

## 🚀 Quick Start

```bash
cd deployments/azure
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
./deploy.sh
```

See **[AZURE_QUICKSTART.md](./AZURE_QUICKSTART.md)** for a 5-minute setup guide.

---

## 📋 Table of Contents

1. [Features](#features)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Directory Structure](#directory-structure)
5. [Installation](#installation)
6. [Configuration](#configuration)
7. [Deployment](#deployment)
8. [Post-Deployment](#post-deployment)
9. [Monitoring](#monitoring)
10. [Scaling](#scaling)
11. [Security](#security)
12. [Disaster Recovery](#disaster-recovery)
13. [Cost Optimization](#cost-optimization)
14. [Troubleshooting](#troubleshooting)
15. [Documentation](#documentation)

---

## ✨ Features

### Core Services

- ✅ **Virtual Machines**: Auto-scaling VM Scale Set (2-10 instances)
- ✅ **Load Balancer**: Azure Load Balancer with health checks
- ✅ **Database**: MySQL 8.0 or PostgreSQL with high availability
- ✅ **Storage**: GZRS blob storage with CDN
- ✅ **Key Vault**: Secure secrets management
- ✅ **Monitoring**: Log Analytics + Application Insights

### High Availability

- ✅ Multi-zone deployment across 3 availability zones
- ✅ Auto-scaling based on CPU and memory
- ✅ Database replication with automatic failover
- ✅ Geo-redundant storage (GZRS)
- ✅ Health checks and auto-healing

### Security

- ✅ Network Security Groups (NSGs) with least-privilege rules
- ✅ Private endpoints for Key Vault and Storage
- ✅ DDoS Protection Standard
- ✅ Azure RBAC integration
- ✅ Encryption at rest and in transit
- ✅ Audit logging for compliance

### Monitoring & Logging

- ✅ Log Analytics workspace (30-day retention)
- ✅ Application Insights for APM
- ✅ Automated alert rules
- ✅ Azure Portal dashboards
- ✅ Diagnostic settings for all services

### Operational Excellence

- ✅ Infrastructure as Code (Terraform)
- ✅ Modular, reusable components
- ✅ Automated deployment scripts
- ✅ Maintenance scripts and runbooks
- ✅ Comprehensive documentation

---

## 🏗️ Architecture

```
                    Internet
                       ↓
                  [Azure Front Door / CDN]
                       ↓
              [Application Gateway / LB]
                  (80, 443)
                       ↓
        ┌──────────────┴──────────────┐
        ↓                              ↓
    [VM-1]                         [VM-2]
   (docker)                       (docker)
   foundry                        foundry
   ↓  ↓  ↓                        ↓  ↓  ↓
DB  ST  LG                       DB  ST  LG

Legend:
- VM: Virtual Machine running Foundry
- DB: Database connection (MySQL/PostgreSQL)
- ST: Storage connection (Blob Storage)
- LG: Logging connection (Log Analytics)
- All in Virtual Network with NSGs
- All data encrypted in transit (HTTPS/TLS)
```

### Network Diagram

```
Virtual Network (10.0.0.0/16)
├── Gateway Subnet (10.0.1.0/24)
│   └── NSG: Allow 80, 443
├── App Subnet (10.0.2.0/23)
│   ├── VM Scale Set (2-10)
│   ├── Private Endpoints (KV, ST)
│   └── NSG: Restricted
├── Database Subnet (10.0.4.0/24)
│   ├── MySQL/PostgreSQL
│   └── NSG: Only from App
└── Storage Subnet (10.0.5.0/24)
    └── NSG: Only from App

External:
├── Key Vault (Private Endpoint)
├── Blob Storage (Private Endpoint)
├── CDN Endpoint
├── Log Analytics
└── Application Insights
```

---

## 📦 Prerequisites

### Required Tools

- Azure CLI 2.40+
- Terraform 1.0+
- Git
- SSH key pair

### Azure Account

- Active Azure subscription
- Permissions to create resources
- Resource group quota
- Quota for compute resources

### Foundry VTT

- Valid Foundry license key (get from https://foundryvtt.com/me/account)
- License key with deployment enabled

### Network

- Available SSH key (or generate new)
- For remote deployment: SSH access to VM

### Installation Commands

```bash
# Install Azure CLI (macOS)
brew install azure-cli

# Install Azure CLI (Linux)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install Terraform (macOS)
brew install terraform

# Install Terraform (Linux)
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip && sudo mv terraform /usr/local/bin/

# Verify installations
az --version
terraform --version
ssh-keygen -h
```

---

## 📁 Directory Structure

```
modules/azure/
├── networking/              # VNets, NSGs, DDoS, NAT Gateway
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── security/                # Key Vault, RBAC, Private Endpoints
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── compute/                 # VMs, Scale Sets, Load Balancer
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── scripts/
│       └── foundry-init.sh
├── database/                # MySQL/PostgreSQL, Backups, HA
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── storage/                 # Blob Storage, CDN, Containers
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── monitoring/              # Log Analytics, Insights, Alerts
    ├── main.tf
    ├── variables.tf
    └── outputs.tf

deployments/azure/
├── main.tf                  # Main orchestration file
├── variables.tf             # Input variables
├── outputs.tf               # Output values
├── terraform.tfvars.example # Configuration template
├── deploy.sh                # Automated deployment script
└── maintenance.sh           # Maintenance automation

Documentation/
├── AZURE_DEPLOYMENT.md      # Comprehensive deployment guide
├── AZURE_QUICKSTART.md      # 5-minute quick start
├── INFRASTRUCTURE_SUMMARY.md # Architecture overview
└── README_AZURE.md          # This file
```

---

## 💻 Installation

### 1. Clone Repository

```bash
cd /path/to/LegendForge-CloudCampaigns
git clone https://github.com/your-repo.git
cd deployments/azure
```

### 2. Login to Azure

```bash
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### 3. Generate SSH Key

```bash
# Generate key (if needed)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/azure_foundry

# Get public key
cat ~/.ssh/azure_foundry.pub
```

### 4. Copy and Configure terraform.tfvars

```bash
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

**Required Variables:**

- `foundry_license_key`: Your Foundry VTT license
- `vm_ssh_public_key`: SSH public key for VM access
- `database_password`: Strong database password
- `alert_email`: Email for alert notifications

---

## ⚙️ Configuration

### Environment Selection

```hcl
environment = "prod"  # dev, staging, prod
location    = "eastus"  # Azure region
project_name = "legendforge"
```

### Compute Sizing

```hcl
# Small deployment
vm_size                = "Standard_B2s"  # 2 vCPU, 4 GB
scale_set_capacity     = 1
scale_set_max_capacity = 3

# Medium deployment
vm_size                = "Standard_D2s_v3"  # 2 vCPU, 8 GB
scale_set_capacity     = 2
scale_set_max_capacity = 5

# Large deployment
vm_size                = "Standard_D4s_v5"  # 4 vCPU, 16 GB
scale_set_capacity     = 3
scale_set_max_capacity = 10
```

### Database Options

```hcl
# MySQL (recommended)
database_engine  = "mysql"
database_version = "8.0"
database_sku_name = "Standard_B2s"

# PostgreSQL
database_engine  = "postgres"
database_version = "14"
database_sku_name = "Standard_B2s"
```

### Features

```hcl
enable_monitoring = true   # Enable Log Analytics
enable_cdn        = true   # Enable CDN for media
geo_redundant_backup_enabled = true
high_availability_enabled = true
```

---

## 🚀 Deployment

### Option 1: Automated Deployment (Recommended)

```bash
cd deployments/azure
./deploy.sh
```

This script:

1. Checks prerequisites
2. Validates configuration
3. Plans deployment
4. Prompts for confirmation
5. Applies Terraform
6. Displays outputs

### Option 2: Manual Deployment

```bash
cd deployments/azure

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan deployment
terraform plan -out=tfplan

# Review plan
# Then apply
terraform apply tfplan

# Show outputs
terraform output
```

### Option 3: CI/CD Pipeline

```bash
# For GitHub Actions, GitLab CI, etc.
terraform init -backend=true
terraform plan -lock=false
terraform apply -auto-approve
```

---

## ✅ Post-Deployment

### 1. Get Outputs

```bash
# Show all outputs
terraform output

# Get specific output
terraform output load_balancer_public_ip

# Save to JSON
terraform output -json > outputs.json
```

### 2. Access Foundry

```bash
# Get public IP
PUBLIC_IP=$(terraform output -raw load_balancer_public_ip)

# Open in browser
open http://$PUBLIC_IP
```

### 3. Configure Foundry

1. Create admin account
2. Import game system
3. Configure worlds
4. Set up modules

### 4. Setup SSL/TLS

```bash
# Generate certificate (or use existing)
openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout /tmp/foundry.key \
  -out /tmp/foundry.crt

# Import to Key Vault
az keyvault certificate import \
  --vault-name kv-legendforge-abc123 \
  --name foundry-cert \
  --file /tmp/foundry.pfx
```

### 5. Configure Custom Domain

```bash
# Update DNS records to point to load balancer IP
# Then update Application Gateway SSL binding
```

---

## 📊 Monitoring

### Azure Portal Dashboard

Visit: `Azure Portal → Search "dashboard-legendforge-prod"`

### View Logs

```bash
# Log Analytics queries
az monitor log-analytics query \
  --workspace-name law-legendforge-prod \
  --analytics-query "AzureDiagnostics | limit 100"
```

### Check Alerts

```bash
# List alert rules
az monitor metrics alert list \
  --resource-group rg-legendforge-prod
```

### Application Insights

```bash
# View application traces
az monitor app-insights query \
  --app ai-legendforge-prod \
  --analytics-query "requests | limit 50"
```

---

## 📈 Scaling

### Auto-Scaling

Automatic based on metrics:

- CPU > 75%: Scale up
- CPU < 25%: Scale down
- Available Memory < 512MB: Scale up
- Maximum: 10 instances

### Manual Scaling

```bash
# Scale to 5 instances
terraform apply -var="scale_set_capacity=5"

# Or via Azure CLI
az vmss scale \
  --resource-group rg-legendforge-prod \
  --name vmss-legendforge-prod \
  --new-capacity 5
```

---

## 🔒 Security

### Network Security

- Restricted NSGs with least-privilege rules
- Private endpoints for services
- DDoS Protection Standard
- NAT Gateway for outbound traffic

### Access Control

- Azure RBAC on all resources
- Managed identities for services
- Service principal authentication
- Multi-factor authentication ready

### Secrets Management

- All sensitive data in Key Vault
- Private endpoint for vault access
- Audit logging enabled
- Automatic key rotation support

### Compliance

- Azure Security Center integration
- Azure Defender enabled
- Audit logs retained 30 days
- RBAC audit trail

---

## 🔄 Disaster Recovery

### Automated Backups

- Database: Daily (35-day retention)
- Storage: Geo-redundant (GZRS)
- Configuration: Blob storage

### Recovery Procedures

```bash
# Restore database
az mysql flexible-server restore \
  --source-server mysql-legendforge-prod \
  --restore-point-in-time "2024-06-28T10:00:00"

# Download storage backup
az storage blob download-batch \
  --source foundry-backups \
  --destination /backup/location
```

---

## 💰 Cost Optimization

### Cost Estimation

```bash
# View resource costs
az costmanagement query list \
  --resource-group rg-legendforge-prod
```

### Reduce Costs

1. Use Standard_B2s for dev: -$300/month
2. Reduce backup retention: -$20/month
3. Disable CDN for dev: -$20/month
4. Use spot instances: -70% compute
5. Set up auto-shutdown for dev

---

## 🔧 Troubleshooting

### Check Scale Set Status

```bash
az vmss show \
  --name vmss-legendforge-prod \
  --resource-group rg-legendforge-prod
```

### View VM Logs

```bash
# Recent Foundry logs
az vmss run-command invoke \
  --resource-group rg-legendforge-prod \
  --name vmss-legendforge-prod \
  --command-id RunShellScript \
  --scripts "docker logs foundry --tail 100"
```

### Database Troubleshooting

```bash
# Test connection
mysql -h mysql-legendforge-prod.mysql.database.azure.com \
  -u azureadmin -p

# Check firewall rules
az mysql flexible-server firewall-rule list \
  --server-name mysql-legendforge-prod \
  --resource-group rg-legendforge-prod
```

### Network Issues

```bash
# Check NSG rules
az network nsg rule list \
  --resource-group rg-legendforge-prod \
  --nsg-name nsg-snet-app

# Check private DNS
az network private-dns zone list \
  --resource-group rg-legendforge-prod
```

---

## 📚 Documentation

1. **[AZURE_QUICKSTART.md](./AZURE_QUICKSTART.md)** - 5-minute setup
2. **[AZURE_DEPLOYMENT.md](./AZURE_DEPLOYMENT.md)** - Comprehensive guide
3. **[INFRASTRUCTURE_SUMMARY.md](./INFRASTRUCTURE_SUMMARY.md)** - Architecture overview
4. **Terraform Docs**: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
5. **Azure Docs**: https://docs.microsoft.com/azure/
6. **Foundry Docs**: https://foundryvtt.com/article/installation/

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make changes
4. Test thoroughly
5. Submit a pull request

---

## ⚖️ License

This infrastructure code is provided as-is. LegendForge is separately licensed.
See https://foundryvtt.com/licensing for Foundry license information.

---

## 📞 Support

For issues:

1. Check **[AZURE_DEPLOYMENT.md](./AZURE_DEPLOYMENT.md)** troubleshooting section
2. Run `./maintenance.sh` for diagnostics
3. Check Azure Portal for resource status
4. Review logs in Log Analytics workspace

---

**Last Updated**: 2024-06-28
**Terraform Version**: 1.6+
**Azure Provider Version**: 3.80+
