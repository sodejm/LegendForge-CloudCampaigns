# LegendForge on Azure - Documentation Index

## 📖 Start Here

**New to this infrastructure?** Start with one of these:

1. **[AZURE_QUICKSTART.md](./AZURE_QUICKSTART.md)** ⭐ START HERE
   - 5-minute setup guide
   - Step-by-step instructions
   - Access Foundry in ~20 minutes
   - Troubleshooting tips

2. **[README_AZURE.md](./README_AZURE.md)** 📚 COMPLETE GUIDE
   - Full feature overview
   - Architecture diagrams
   - Prerequisites checklist
   - All deployment options
   - Monitoring setup
   - Security details

## 📋 Detailed Documentation

### Core Documentation

- **[AZURE_DEPLOYMENT.md](./AZURE_DEPLOYMENT.md)** - Comprehensive 5,000+ line guide
  - Architecture with ASCII diagrams
  - Component-by-component explanation
  - Prerequisites and setup
  - Configuration options
  - Monitoring & alerting setup
  - Security best practices
  - Scaling recommendations
  - Disaster recovery
  - Troubleshooting with commands
  - Post-deployment configuration

- **[INFRASTRUCTURE_SUMMARY.md](./INFRASTRUCTURE_SUMMARY.md)** - Architecture overview
  - Project structure
  - Service descriptions
  - Cost breakdown
  - High availability features
  - Security features checklist
  - Maintenance schedule
  - Scaling table

- **[AZURE_BUILD_SUMMARY.txt](./AZURE_BUILD_SUMMARY.txt)** - Build completion report
  - What was created
  - Module descriptions
  - Service inventory
  - Features checklist
  - Verification list

## 🗂️ Project Structure

```
modules/azure/
├── networking/              # Virtual Networks, Security Groups, DDoS
├── security/                # Key Vault, RBAC, Private Endpoints
├── compute/                 # VMs, Scale Sets, Load Balancer
├── database/                # MySQL/PostgreSQL with HA
├── storage/                 # Blob Storage, CDN
└── monitoring/              # Logging, Alerts, Dashboards

deployments/azure/
├── main.tf                  # Main orchestration
├── variables.tf             # Configuration
├── terraform.tfvars.example # Template
├── deploy.sh                # Automated deployment
└── maintenance.sh           # Maintenance tasks
```

## ⚡ Quick Commands

### Deploy
```bash
cd deployments/azure
./deploy.sh
```

### Maintain
```bash
./maintenance.sh
```

### Get Outputs
```bash
terraform output
```

### Access Foundry
```bash
# Get IP from outputs, then visit:
http://<LOAD_BALANCER_IP>
```

## 🎯 Use Case Guides

### First Time Setup
1. Read: [AZURE_QUICKSTART.md](./AZURE_QUICKSTART.md)
2. Run: `./deploy.sh`
3. Access: `http://<LOAD_BALANCER_IP>`

### Production Deployment
1. Read: [AZURE_DEPLOYMENT.md](./AZURE_DEPLOYMENT.md) - Full guide
2. Configure: `terraform.tfvars` with production values
3. Deploy: `./deploy.sh`
4. Monitor: Azure Portal dashboards
5. Secure: Configure SSL/TLS and custom domain

### Cost Optimization
1. Check: [INFRASTRUCTURE_SUMMARY.md](./INFRASTRUCTURE_SUMMARY.md) - Cost section
2. Adjust: `terraform.tfvars` variables (VM size, backup retention)
3. Deploy: `terraform apply`

### Troubleshooting
1. Check: [AZURE_DEPLOYMENT.md](./AZURE_DEPLOYMENT.md) - Troubleshooting section
2. Use: `./maintenance.sh` - Diagnostics
3. Review: Azure Portal logs and metrics

### Scaling Up
1. Read: [AZURE_DEPLOYMENT.md](./AZURE_DEPLOYMENT.md) - Scaling section
2. Update: `scale_set_capacity` and `scale_set_max_capacity`
3. Deploy: `terraform apply`

### Disaster Recovery
1. Read: [AZURE_DEPLOYMENT.md](./AZURE_DEPLOYMENT.md) - DR section
2. Backups: Automatically created (35-day retention)
3. Restore: Use commands in troubleshooting section

## 🔍 Finding Specific Topics

### Security
- Network Security: [AZURE_DEPLOYMENT.md](./AZURE_DEPLOYMENT.md#network-security)
- Secrets Management: [AZURE_DEPLOYMENT.md](./AZURE_DEPLOYMENT.md#secrets-management)
- SSL/TLS: [AZURE_DEPLOYMENT.md](./AZURE_DEPLOYMENT.md#ssltls-configuration)
- RBAC: [AZURE_DEPLOYMENT.md](./AZURE_DEPLOYMENT.md#identity--access-management)

### Monitoring
- Setup: [AZURE_DEPLOYMENT.md](./AZURE_DEPLOYMENT.md#monitoring--alerts)
- Access Dashboards: [AZURE_DEPLOYMENT.md](./AZURE_DEPLOYMENT.md#access-monitoring-dashboard)
- Query Logs: [AZURE_DEPLOYMENT.md](./AZURE_DEPLOYMENT.md#application-insights-queries)

### Scaling
- Auto-scaling: [AZURE_DEPLOYMENT.md](./AZURE_DEPLOYMENT.md#auto-scaling-policies)
- Manual Scaling: [AZURE_DEPLOYMENT.md](./AZURE_DEPLOYMENT.md#manual-scaling)
- Performance Tuning: [AZURE_DEPLOYMENT.md](./AZURE_DEPLOYMENT.md#performance-tuning)

### Costs
- Estimation: [INFRASTRUCTURE_SUMMARY.md](./INFRASTRUCTURE_SUMMARY.md#resource-costs-estimated-monthly)
- Optimization: [AZURE_DEPLOYMENT.md](./AZURE_DEPLOYMENT.md#cost-optimization)
- Calculations: [AZURE_QUICKSTART.md](./AZURE_QUICKSTART.md#costs)

### Troubleshooting
- Common Issues: [AZURE_DEPLOYMENT.md](./AZURE_DEPLOYMENT.md#common-issues)
- Debug Commands: [AZURE_DEPLOYMENT.md](./AZURE_DEPLOYMENT.md#debug-commands)
- Logs: [AZURE_DEPLOYMENT.md](./AZURE_DEPLOYMENT.md#viewing-logs)

## 📚 Learning Path

### Level 1: Understand (15 minutes)
1. Read [AZURE_QUICKSTART.md](./AZURE_QUICKSTART.md)
2. Skim [INFRASTRUCTURE_SUMMARY.md](./INFRASTRUCTURE_SUMMARY.md)
3. Review architecture diagrams

### Level 2: Prepare (30 minutes)
1. Gather prerequisites
2. Copy `terraform.tfvars.example` to `terraform.tfvars`
3. Edit configuration values
4. Generate SSH key if needed

### Level 3: Deploy (30 minutes)
1. Run `./deploy.sh`
2. Monitor deployment progress
3. Wait for completion (~20 minutes)
4. Access Foundry application

### Level 4: Configure (30 minutes)
1. Setup admin account
2. Import game system
3. Configure worlds
4. Install modules

### Level 5: Secure (1 hour)
1. Read security sections in [AZURE_DEPLOYMENT.md](./AZURE_DEPLOYMENT.md)
2. Configure SSL/TLS
3. Setup custom domain
4. Review RBAC permissions

### Level 6: Monitor (15 minutes)
1. Access Azure Portal
2. View dashboards
3. Setup alert emails
4. Review logs

### Level 7: Optimize (ongoing)
1. Monitor costs
2. Review performance metrics
3. Adjust auto-scaling policies
4. Plan capacity

## 🛠️ Tools & Scripts

### Deployment
- **deploy.sh**: One-command deployment
  ```bash
  ./deploy.sh
  ```

### Operations
- **maintenance.sh**: Operational tasks menu
  ```bash
  ./maintenance.sh
  ```

### Initialization
- **foundry-init.sh**: Automatic VM setup
  - Runs automatically via cloud-init
  - No manual execution needed

### Configuration Template
- **terraform.tfvars.example**: Configuration reference
  - Copy and edit with your values
  - Includes all available options

## 📊 Resource Overview

### What Gets Created

**Compute**
- Virtual Machine Scale Set (2-10 instances)
- Load Balancer with health checks
- Auto-scaling based on CPU/memory

**Database**
- MySQL 8.0 or PostgreSQL Flexible Server
- Zone-redundant high availability
- 35-day automated backups

**Storage**
- Blob storage with GZRS (geo-redundant)
- CDN for media delivery
- 4 containers for Foundry data

**Security**
- Key Vault for secrets
- Network Security Groups
- Private endpoints

**Monitoring**
- Log Analytics workspace
- Application Insights
- Alert rules and dashboards

**Network**
- Virtual Network (10.0.0.0/16)
- 4 subnets (Gateway, App, DB, Storage)
- DDoS Protection
- NAT Gateway

## 💰 Costs

**Estimated Monthly: ~$556**

| Service | Cost |
|---------|------|
| VMs (2x D4s) | $385 |
| Database | $100 |
| Storage | $10 |
| CDN | $20 |
| Other | $41 |
| **Total** | **$556** |

See [INFRASTRUCTURE_SUMMARY.md](./INFRASTRUCTURE_SUMMARY.md#resource-costs-estimated-monthly) for detailed breakdown.

## ✅ Deployment Checklist

- [ ] Review [AZURE_QUICKSTART.md](./AZURE_QUICKSTART.md)
- [ ] Install Azure CLI and Terraform
- [ ] Get Foundry license key
- [ ] Generate SSH key
- [ ] Have alert email ready
- [ ] Copy `terraform.tfvars.example` → `terraform.tfvars`
- [ ] Edit configuration values
- [ ] Run `./deploy.sh`
- [ ] Wait for deployment (~20 minutes)
- [ ] Access Foundry at load balancer IP
- [ ] Configure admin account
- [ ] Setup SSL/TLS (optional)
- [ ] Configure custom domain (optional)

## 🆘 Getting Help

### Documentation
- [AZURE_DEPLOYMENT.md](./AZURE_DEPLOYMENT.md) - Comprehensive guide
- [AZURE_QUICKSTART.md](./AZURE_QUICKSTART.md) - Quick start
- [README_AZURE.md](./README_AZURE.md) - Full project docs

### Scripts
- `./deploy.sh` - Automated deployment
- `./maintenance.sh` - Maintenance tasks

### External Resources
- [Azure Docs](https://docs.microsoft.com/azure/)
- [Terraform Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Foundry Docs](https://foundryvtt.com/article/installation/)

## 📞 Common Questions

**Q: How long does deployment take?**
A: ~20 minutes from running `./deploy.sh`

**Q: What's the minimum cost?**
A: ~$300/month with Standard_B2s VMs

**Q: Can I change the database?**
A: Yes, MySQL (default) or PostgreSQL in `terraform.tfvars`

**Q: How do I scale manually?**
A: Use `./maintenance.sh` option 6, or edit `scale_set_capacity`

**Q: Is SSL/TLS included?**
A: Setup via Key Vault (see [AZURE_DEPLOYMENT.md](./AZURE_DEPLOYMENT.md#ssltls-configuration))

**Q: How do I backup data?**
A: Automatic backups enabled (35 days). See [AZURE_DEPLOYMENT.md](./AZURE_DEPLOYMENT.md#backup--recovery-commands)

**Q: How do I delete everything?**
A: `terraform destroy` (see [AZURE_DEPLOYMENT.md](./AZURE_DEPLOYMENT.md#destroy-infrastructure))

## 📄 File Guide

| File | Purpose | Read Time |
|------|---------|-----------|
| [AZURE_QUICKSTART.md](./AZURE_QUICKSTART.md) | Fast setup | 5 min |
| [README_AZURE.md](./README_AZURE.md) | Full overview | 30 min |
| [AZURE_DEPLOYMENT.md](./AZURE_DEPLOYMENT.md) | Detailed guide | 2+ hours |
| [INFRASTRUCTURE_SUMMARY.md](./INFRASTRUCTURE_SUMMARY.md) | Architecture | 15 min |
| [AZURE_BUILD_SUMMARY.txt](./AZURE_BUILD_SUMMARY.txt) | Build report | 10 min |
| This file (AZURE_INDEX.md) | Navigation | 5 min |

## 🎓 Learning Outcomes

After working with this infrastructure, you'll understand:

- ✅ Azure Infrastructure as Code (Terraform)
- ✅ Virtual Networks and Security
- ✅ Virtual Machine Scale Sets and Auto-scaling
- ✅ Database High Availability
- ✅ Blob Storage and CDN
- ✅ Monitoring and Logging
- ✅ Key Vault and Secrets Management
- ✅ RBAC and Identity Management
- ✅ Disaster Recovery and Backups
- ✅ Cost Optimization

## 🚀 You're Ready!

1. **Start with**: [AZURE_QUICKSTART.md](./AZURE_QUICKSTART.md)
2. **Deep dive with**: [AZURE_DEPLOYMENT.md](./AZURE_DEPLOYMENT.md)
3. **Run**: `./deploy.sh`
4. **Access**: Foundry at load balancer IP
5. **Maintain**: Use `./maintenance.sh`

---

**Questions?** Check [AZURE_DEPLOYMENT.md](./AZURE_DEPLOYMENT.md#troubleshooting) troubleshooting section.

**Last Updated**: 2024-06-28
**Status**: Production Ready ✅
