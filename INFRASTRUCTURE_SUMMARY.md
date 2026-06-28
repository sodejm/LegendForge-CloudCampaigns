# LegendForge - Azure Infrastructure Summary

## Project Structure

```
LegendForge-CloudCampaigns/
├── modules/azure/
│   ├── networking/              # VNets, Subnets, NSGs, DDoS
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── security/                # Key Vault, RBAC, Private Endpoints
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── compute/                 # VMs, Scale Sets, Load Balancer
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── scripts/
│   │       └── foundry-init.sh
│   ├── database/                # MySQL/PostgreSQL, Backups
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── storage/                 # Blob Storage, CDN, Containers
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── monitoring/              # Log Analytics, Insights, Alerts
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── deployments/azure/
│   ├── main.tf                  # Main orchestration
│   ├── variables.tf             # Input variables
│   ├── outputs.tf               # Output values
│   ├── terraform.tfvars.example # Configuration template
│   ├── deploy.sh                # Deployment automation
│   └── maintenance.sh           # Maintenance tasks
│
├── AZURE_DEPLOYMENT.md          # Comprehensive guide
├── AZURE_QUICKSTART.md          # 5-minute quickstart
└── INFRASTRUCTURE_SUMMARY.md    # This file
```

---

## Azure Services Deployed

### 1. **Networking**
- **Azure Virtual Network** (10.0.0.0/16)
  - Gateway Subnet (10.0.1.0/24) - Application Gateway/Load Balancer
  - App Subnet (10.0.2.0/23) - VM Scale Set instances
  - Database Subnet (10.0.4.0/24) - MySQL/PostgreSQL
  - Storage Subnet (10.0.5.0/24) - Storage & KeyVault endpoints

- **Network Security Groups (NSGs)**
  - Gateway NSG: Allow HTTP/HTTPS (80, 443)
  - App NSG: Restricted access to DB and Storage
  - Database NSG: Only from App subnet
  - Storage NSG: Only from App subnet

- **DDoS Protection Standard**
  - Layer 3/4 attack protection
  - Real-time attack metrics

- **NAT Gateway**
  - Static outbound IP for whitelisting
  - Applied to App subnet

### 2. **Security**
- **Azure Key Vault**
  - License keys, passwords, connection strings
  - Private endpoint access
  - Purge protection enabled
  - Audit logging
  - RBAC controlled access

- **Private Endpoints**
  - Key Vault private access
  - Storage Blob private access
  - Secures internal traffic

- **Private DNS Zones**
  - privatelink.vaultcore.azure.net
  - privatelink.blob.core.windows.net

### 3. **Compute**
- **VM Scale Set** (2-10 instances)
  - Auto-scaling based on CPU (>75%) and memory (<512MB)
  - Distributed across availability zones (1, 2, 3)
  - Ubuntu 20.04 LTS images
  - Managed identity for secure service access
  - Docker-based Foundry deployment

- **Azure Load Balancer**
  - Standard SKU with zone redundancy
  - Backend pool for scale set
  - Health probes (HTTP/HTTPS)
  - Load balancing rules on ports 80/443
  - Public static IP

- **Auto-scaling Policies**
  - CPU-based: Scale up at 75%, down at 25%
  - Memory-based: Scale up when <512MB available
  - Cooldown: 5 minutes between actions
  - Smooth updates: 30% max batch

### 4. **Database**
- **MySQL Flexible Server** (or PostgreSQL option)
  - SKU: Standard_B2s (2 vCore, 4 GB RAM)
  - Zone-redundant high availability
  - Automatic daily backups (35 days retention)
  - Geo-redundant backup storage
  - Private endpoint access only
  - Auto-configured for Foundry

- **Database Security**
  - Firewall rules restricted to App subnet
  - Private network deployment
  - SSL/TLS encryption
  - Audit logging enabled

### 5. **Storage**
- **Azure Blob Storage**
  - Geo-Zone-Redundant (GZRS): 6 copies across zones & regions
  - Premium tier
  - Containers:
    - foundry-data: User data and configurations
    - foundry-worlds: Campaign worlds
    - foundry-modules: Add-on modules
    - foundry-media: Maps, tokens, assets

- **Azure CDN**
  - Content delivery for media files
  - Microsoft standard endpoint
  - CORS enabled for web access
  - Caching policies configured

- **Storage Security**
  - Private endpoints for app access
  - HTTPS only enforced
  - Blob access roles (Contributor, Reader)
  - Audit logging enabled

### 6. **Monitoring & Logging**
- **Log Analytics Workspace**
  - 30 days retention
  - Aggregates logs from all services
  - Custom queries and views

- **Application Insights**
  - APM for Foundry application
  - Request/dependency tracking
  - Performance analysis
  - Custom events logging

- **Diagnostic Settings**
  - NSG flow logs
  - Load balancer diagnostics
  - Storage account metrics
  - Database slow query logs
  - Key Vault audit logs

- **Alert Rules**
  - High CPU (>80% for 5 min)
  - Low Memory (<512MB)
  - Database CPU (>85%)
  - Storage quota (>80%)
  - Action group for email notifications

- **Azure Dashboard**
  - Resource group view
  - VM Scale Set metrics
  - Real-time performance graphs

---

## Resource Costs (Estimated Monthly)

| Service | Size | Unit Cost | Monthly |
|---------|------|-----------|---------|
| VM Scale Set | 2x D4s_v5 | $0.264/hr | $385 |
| Database | Standard_B2s | $90-120 | $100 |
| Storage | 100GB GZRS | $0.10/GB | $10 |
| CDN | Data transfer | $0.085/GB | $20 |
| Public IPs | 2x Standard | $3.65/month | $7 |
| Load Balancer | Standard | $0.025/hr | $18 |
| Key Vault | 10k ops | $0.34/10k | $1 |
| Log Analytics | Pay-as-you-go | $2.30/GB | $15 |
| **Total** | | | **$556** |

**Savings Opportunities:**
- Use Standard_B2s for dev: Save $300/month
- Reduce backup retention: Save $20/month
- Spot instances: Save 70% on compute

---

## Deployment Workflow

### 1. **Pre-Deployment** (5 minutes)
```bash
# Install tools
az login
terraform init

# Prepare variables
cp terraform.tfvars.example terraform.tfvars
# Edit with your values
```

### 2. **Planning** (5 minutes)
```bash
terraform plan -out=tfplan
# Review changes
```

### 3. **Deployment** (20 minutes)
```bash
terraform apply tfplan
# Watch Azure Portal for resource creation
```

### 4. **Post-Deployment** (10 minutes)
```bash
# Get outputs
terraform output

# Access Foundry
open http://<LOAD_BALANCER_IP>

# Configure monitoring alerts
az monitor metrics alert list -g rg-legendforge-prod
```

---

## High Availability Features

✅ **Multi-Zone**: Resources in 3 availability zones
✅ **Auto-Healing**: Unhealthy VMs replaced automatically
✅ **Auto-Scaling**: 2-10 instances based on demand
✅ **Database Failover**: Automatic zone-redundant HA
✅ **Geo-Redundancy**: Data replicated across regions
✅ **Load Balancing**: Automatic traffic distribution
✅ **Health Checks**: Continuous endpoint monitoring
✅ **Backup & Recovery**: 35-day retention with restore

---

## Security Features

✅ **Network Security**
- NSGs with least-privilege rules
- Private endpoints for internal services
- DDoS Protection Standard
- NAT Gateway for outbound traffic

✅ **Identity & Access**
- Azure RBAC on all resources
- Managed identities for services
- Service principal authentication
- Multi-factor authentication ready

✅ **Secrets Management**
- All sensitive data in Key Vault
- No secrets in code or configs
- Audit logging of secret access
- Automatic rotation ready

✅ **Encryption**
- HTTPS enforced on all connections
- Storage encryption at rest
- Database SSL/TLS encryption
- Key Vault HSM backup (premium tier)

✅ **Compliance**
- Audit logging for all services
- Azure Security Center integration
- RBAC role assignments logged
- Data residency in selected region

---

## Monitoring & Alerts

### Default Alert Rules

1. **VM CPU Usage**
   - Triggers when avg > 80%
   - Scale up by 1 instance
   - Cooldown 5 minutes

2. **Available Memory**
   - Triggers when < 512MB
   - Scale up by 1 instance

3. **Database CPU**
   - Alert when > 85%
   - Email notification

4. **Storage Capacity**
   - Alert when > 80% full
   - Email notification

### Access Monitoring

```bash
# View dashboard
az portal show --name dashboard-legendforge-prod

# Query logs
az monitor log-analytics query --workspace-name law-legendforge-prod

# View metrics
az monitor metrics list --resource <RESOURCE_ID>
```

---

## Disaster Recovery

### Automated Backups

- **Database**: Daily automated backups (35 days)
- **Storage**: Geo-redundant replication (GZRS)
- **VMs**: Scale set snapshots available
- **Configs**: Stored in secure blob storage

### Recovery Procedures

```bash
# Restore database from backup
az mysql flexible-server restore \
  --source-server mysql-legendforge-prod \
  --restore-point-in-time "2024-06-28T10:00:00"

# Restore storage data
az storage blob download-batch \
  --source foundry-backups
```

### Recovery Time Objectives (RTO)

- **Database failure**: 5 minutes (automatic failover)
- **VM failure**: 2 minutes (auto-healing)
- **Regional outage**: Setup Traffic Manager for 15 minutes

---

## Maintenance Tasks

### Weekly
- Check alert status
- Review scaling events
- Monitor database performance

### Monthly
- Rotate database password
- Review access logs
- Test restore procedures
- Analyze cost trends

### Quarterly
- Security audit
- Capacity planning
- Update VM images
- Review disaster recovery plan

### Use Maintenance Script
```bash
./deployments/azure/maintenance.sh
```

---

## Scaling Recommendations

| Users | Concurrent | CPU | Memory | VM Size | Count |
|-------|-----------|-----|--------|---------|-------|
| 10-50 | 5-10 | Low | 2GB | B2s | 1 |
| 50-200 | 20-40 | Low | 4GB | B4ms | 2 |
| 200-500 | 40-100 | Medium | 8GB | D2s_v3 | 2-4 |
| 500+ | 100+ | High | 16GB | D4s_v5 | 4-10 |

---

## Next Steps

1. **Review AZURE_QUICKSTART.md** for 5-minute setup
2. **Read AZURE_DEPLOYMENT.md** for detailed guide
3. **Run `./deploy.sh`** to automate deployment
4. **Configure SSL/TLS** with Application Gateway
5. **Setup monitoring** email alerts
6. **Create backup** procedures
7. **Test disaster** recovery

---

## Support & Resources

- **Terraform Docs**: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
- **Azure Docs**: https://docs.microsoft.com/azure/
- **Foundry Docs**: https://foundryvtt.com/article/installation/
- **Azure CLI**: https://docs.microsoft.com/cli/azure/

---

## Revision History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2024-06-28 | Initial infrastructure release |
| - | - | - |

---

**Infrastructure as Code Version**: 1.0
**Last Updated**: 2024-06-28
**Maintained By**: DevOps Team
