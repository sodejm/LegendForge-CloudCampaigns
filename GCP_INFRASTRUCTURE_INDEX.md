# LegendForge on Google Cloud Platform - Complete Index

## 🎯 Overview

This repository contains **production-ready Terraform infrastructure code** for deploying LegendForge on Google Cloud Platform. The complete setup includes **8 modular components** covering networking, compute, database, storage, load balancing, monitoring, security, and secrets management.

---

## 📚 Documentation Map

### 🚀 Start Here
1. **[GCP_MODULES_SUMMARY.md](./GCP_MODULES_SUMMARY.md)** ← YOU ARE HERE
   - Overview of all 8 modules
   - Key features and capabilities
   - Quick start summary
   - Cost estimation

### 📖 Detailed Guides

2. **[deployments/gcp/README.md](./deployments/gcp/README.md)**
   - Package overview
   - Features and benefits
   - Quick start (5 steps)
   - FAQ and troubleshooting

3. **[deployments/gcp/DEPLOYMENT_GUIDE.md](./deployments/gcp/DEPLOYMENT_GUIDE.md)** ⭐ **PRIMARY GUIDE**
   - Step-by-step deployment instructions
   - GCP setup and prerequisites
   - Terraform workflow
   - Post-deployment configuration
   - Monitoring and maintenance
   - Scaling and cost optimization
   - Troubleshooting guide

4. **[deployments/gcp/ARCHITECTURE.md](./deployments/gcp/ARCHITECTURE.md)**
   - System architecture diagrams
   - Component details
   - Data flow diagrams
   - HA and DR strategies
   - Performance characteristics
   - Scalability roadmap

5. **[deployments/gcp/QUICK_REFERENCE.md](./deployments/gcp/QUICK_REFERENCE.md)**
   - Common commands and operations
   - Terraform commands
   - GCP CLI commands
   - Database operations
   - Storage operations
   - Emergency procedures

### ⚙️ Configuration

6. **[deployments/gcp/terraform.tfvars.example](./deployments/gcp/terraform.tfvars.example)**
   - Configuration template
   - All available variables
   - Default values
   - Comments and examples

---

## 📁 Code Structure

### Modules (Reusable Components)

```
modules/
├── gcp-vpc/              ← VPC networking, subnets, firewall, NAT
├── gcp-iam/              ← Service accounts, roles, permissions
├── gcp-cloudsql/         ← PostgreSQL database with HA
├── gcp-storage/          ← Cloud Storage buckets with lifecycle
├── gcp-compute/          ← Compute Engine instances, scaling
├── gcp-loadbalancer/     ← HTTPS load balancer, CDN, Cloud Armor
├── gcp-monitoring/       ← Dashboards, alerts, logging
└── gcp-secrets/          ← Secret Manager, KMS encryption
```

Each module includes:
- `main.tf` - Core resource definitions
- `variables.tf` - Input variables with validation
- `outputs.tf` - Output values for other modules

### Deployment (Orchestration)

```
deployments/gcp/
├── main.tf                          ← Main orchestration (calls all modules)
├── variables.tf                     ← Deployment-level variables
├── terraform.tfvars.example         ← Configuration template
├── README.md                        ← Quick reference
├── DEPLOYMENT_GUIDE.md              ← Step-by-step guide
├── ARCHITECTURE.md                  ← Design documentation
├── QUICK_REFERENCE.md               ← Common commands
└── templates/
    └── cloud-init.yaml              ← Instance startup script
```

---

## 🏗️ The 8 Modules Explained

### 1️⃣ VPC Networking (`gcp-vpc`)
**What it does**: Creates isolated network environment
- VPC network with configurable subnets
- Cloud NAT for secure outbound internet
- Firewall rules (least privilege)
- Support for multi-region setup

**Key Resources**:
- VPC network
- Subnets (primary + secondary)
- Cloud Router
- Cloud NAT
- Firewall rules (5 types)

**Typical Cost**: ~$0-5/month

---

### 2️⃣ IAM & Service Accounts (`gcp-iam`)
**What it does**: Implements least-privilege access control
- 5 specialized service accounts
- Custom IAM roles
- Pre-configured bindings

**Service Accounts**:
- `foundry-compute` - Instances (logging, monitoring, secrets)
- `foundry-cloudsql` - Database operations
- `foundry-storage` - Cloud Storage access
- `foundry-monitoring` - Dashboards and alerts
- `foundry-secrets` - Secret Manager access

**Key Principle**: Each service account has ONLY the permissions it needs

**Typical Cost**: Free (IAM is always free)

---

### 3️⃣ Cloud SQL Database (`gcp-cloudsql`)
**What it does**: Provides highly-available PostgreSQL database
- Regional HA (primary + standby replica)
- Automatic failover
- Automated daily backups (30-day retention)
- Point-in-time recovery (7 days)
- Optional read replicas for DR
- Performance Insights

**Key Features**:
- PostgreSQL 15.x (configurable)
- Private IP only (inside VPC)
- SSL/TLS encryption
- Query Insights enabled
- Automatic backup retention

**Machine Types** (configurable):
- `db-custom-2-7680` (2 vCPU, 7.5GB) - Small/Medium
- `db-custom-4-16384` (4 vCPU, 16GB) - Medium/Large
- `db-custom-8-32768` (8 vCPU, 32GB) - Large

**Typical Cost**: $180-400/month (depends on machine type)

---

### 4️⃣ Cloud Storage (`gcp-storage`)
**What it does**: Provides persistent file storage with versioning
- 4 specialized buckets:
  - **Data**: Worlds, user data, system files
  - **Media**: Images, sounds, videos
  - **Backups**: Database exports
  - **Logs**: Audit trails

**Key Features**:
- Versioning (keep 3-5 versions)
- Lifecycle policies (auto-archive old data)
- Encryption (Cloud KMS optional)
- Uniform access control
- Audit logging

**Storage Tiers** (automatic):
- STANDARD (0-30 days)
- NEARLINE (30-90 days) - 25% cheaper
- COLDLINE (90-365 days) - 60% cheaper
- ARCHIVE (365+ days) - 80% cheaper

**Typical Cost**: $20-100/month (depends on data size)

---

### 5️⃣ Compute Engine (`gcp-compute`)
**What it does**: Runs Foundry VTT with auto-scaling
- Instance template with cloud-init startup
- Managed instance group across 3 zones
- Auto-healing (replaces failed instances)
- Horizontal auto-scaling (CPU-based)
- Health checks
- Shielded VM security

**Machine Types** (configurable):
- `n2-standard-2` (2 vCPU, 8GB) - Small (5-10 players)
- `n2-standard-4` (4 vCPU, 16GB) - Medium (25 players)
- `n2-standard-8` (8 vCPU, 32GB) - Large (50+ players)

**Scaling**:
- Min replicas: 2 (configurable)
- Max replicas: 5 (configurable)
- CPU target: 70% (configurable)
- Scale-up time: ~2 minutes
- Scale-down time: ~10 minutes

**Typical Cost**: $131-524/month (depends on machine type & replicas)

---

### 6️⃣ Load Balancer & CDN (`gcp-loadbalancer`)
**What it does**: Distributes traffic, terminates SSL, protects from DDoS
- Global HTTPS load balancer (anycast)
- SSL/TLS certificate (Google-managed)
- Cloud CDN for static assets
- Cloud Armor (DDoS/WAF protection)
- Session affinity for WebSocket
- Rate limiting and attack detection

**Key Features**:
- Automatic SSL certificate provisioning
- HTTP redirects to HTTPS
- Cloud CDN caching (1 hour TTL default)
- Rate limiting (100 req/min per IP)
- SQL injection detection
- XSS detection
- Optional: DDoS adaptive protection

**Typical Cost**: $20-50/month

---

### 7️⃣ Monitoring & Alerting (`gcp-monitoring`)
**What it does**: Provides real-time visibility and alerting
- Custom monitoring dashboard
- Alert policies (CPU, memory, health, database)
- Uptime checks (3 global regions)
- Centralized logging
- Error tracking
- Support for email/Slack/PagerDuty notifications

**Dashboard Metrics**:
- Compute CPU and memory utilization
- Network in/out
- Load balancer health
- Cloud SQL CPU and connections
- Custom application metrics

**Alert Policies**:
- CPU > 80% → Alert
- Memory > 85% → Alert
- Backend unhealthy → Alert
- Cloud SQL high CPU → Alert
- Uptime check failures → Alert
- Error spike detected → Alert

**Typical Cost**: Free (monitoring is free, alerting is free)

---

### 8️⃣ Secret Management (`gcp-secrets`)
**What it does**: Securely stores and manages sensitive data
- GCP Secret Manager integration
- Cloud KMS encryption
- IAM-based access control
- Audit logging

**Secrets Stored**:
- Database password
- Foundry license key
- Foundry admin key
- Foundry account credentials
- Cloudflare tunnel token

**Security Features**:
- Encrypted at rest (Cloud KMS)
- Encrypted in transit (TLS)
- Access logged and audited
- Automatic rotation support
- Least-privilege access via IAM

**Typical Cost**: Free (first 6 per month free, $0.06 per additional)

---

## 💰 Cost Breakdown

### Example: Small Campaign (5-10 players)

| Component | Type | Quantity | Cost/Unit | Monthly |
|-----------|------|----------|-----------|---------|
| Compute Engine | n2-standard-2 | 2-5 instances | $0.09/hour | $131 |
| Cloud SQL | db-custom-2-7680 | 1 (HA) | $0.25/hour | $180 |
| Cloud Storage | Multiple buckets | 1TB | $0.020/GB | $20 |
| Load Balancer | Global HTTPS | 1 | Fixed | $20 |
| Network | Cloud NAT | 1 | Per GB | $0-10 |
| Monitoring | Dashboard + Alerts | Unlimited | Free | $0 |
| **Total** | | | | **~$350/mo** |

**Savings with 1-year CUD**: ~$90/month (25% discount)
**Savings with 3-year CUD**: ~$175/month (50% discount)

---

## 🚀 Deployment Workflow

### 1. Preparation (30 minutes)
```
├─ Create GCP project
├─ Enable APIs
├─ Create service account
├─ Obtain Foundry license key
├─ Create Cloudflare tunnel
└─ Prepare domain name
```

### 2. Configuration (15 minutes)
```
├─ Copy terraform.tfvars.example
├─ Edit with your values
├─ Validate syntax
└─ Review plan
```

### 3. Deployment (15-20 minutes)
```
├─ terraform init
├─ terraform plan
├─ terraform apply
├─ Wait for resources to create
└─ Capture outputs
```

### 4. Finalization (10-15 minutes)
```
├─ Update DNS
├─ Wait for SSL cert (10-15 min)
├─ Test HTTPS access
└─ Configure alerts
```

**Total Time**: 60-90 minutes (first time)

---

## ✅ Feature Checklist

### High Availability
- [x] Multi-zone instances (3 zones)
- [x] Auto-healing
- [x] Cloud SQL HA
- [x] Global load balancer
- [x] Health checks
- [x] Auto-failover

### Security
- [x] VPC with private networking
- [x] Firewall rules (least privilege)
- [x] IAM service accounts
- [x] Cloud Armor (DDoS/WAF)
- [x] Cloud KMS encryption
- [x] Secret Manager
- [x] SSL/TLS for all connections
- [x] VPC Flow Logs
- [x] Audit logging
- [x] Shielded VMs

### Scalability
- [x] Horizontal auto-scaling
- [x] Cloud CDN
- [x] Connection pooling
- [x] Circuit breakers

### Performance
- [x] Global anycast routing
- [x] Multi-zone deployment
- [x] CDN caching
- [x] Session affinity
- [x] Query Insights

### Data Protection
- [x] Automated backups
- [x] Point-in-time recovery
- [x] Cloud Storage versioning
- [x] Lifecycle policies
- [x] Encrypted at rest
- [x] Encrypted in transit

### Monitoring
- [x] Dashboards
- [x] Alert policies
- [x] Uptime checks
- [x] Centralized logging
- [x] Error tracking
- [x] Performance metrics

---

## 📞 Quick Help

### "I'm new to this, where do I start?"
**→ Read**: [deployments/gcp/DEPLOYMENT_GUIDE.md](./deployments/gcp/DEPLOYMENT_GUIDE.md)

### "I need to run a command, what is it?"
**→ Check**: [deployments/gcp/QUICK_REFERENCE.md](./deployments/gcp/QUICK_REFERENCE.md)

### "How does this architecture work?"
**→ Read**: [deployments/gcp/ARCHITECTURE.md](./deployments/gcp/ARCHITECTURE.md)

### "I want to understand the modules"
**→ Check**: [GCP_MODULES_SUMMARY.md](./GCP_MODULES_SUMMARY.md)

### "I'm deploying this, what values do I need?"
**→ Use**: [deployments/gcp/terraform.tfvars.example](./deployments/gcp/terraform.tfvars.example)

---

## 🎯 Success Indicators

After deployment, you should have:

✅ Foundry VTT running at your domain (HTTPS)
✅ Multiple instances auto-scaling
✅ Database with HA and backups
✅ Monitoring dashboard showing metrics
✅ Alert policies active
✅ Cloud Storage buckets populated
✅ Private database (no public access)
✅ Cloud Armor protecting from DDoS

---

## 📊 Production Readiness

| Aspect | Status | Details |
|--------|--------|---------|
| High Availability | ✅ READY | Multi-zone, auto-healing, failover |
| Disaster Recovery | ✅ READY | Backups, point-in-time recovery |
| Security | ✅ READY | KMS, IAM, Cloud Armor, VPC |
| Scalability | ✅ READY | Auto-scaling, CDN, load balancing |
| Monitoring | ✅ READY | Dashboards, alerts, logging |
| Cost Optimization | ✅ READY | Auto-scaling, storage lifecycle, CUD support |
| Documentation | ✅ READY | 5 comprehensive guides |

**Overall Status**: **PRODUCTION-READY** ✅

---

## 🔄 Next Steps

1. **Review Documentation**
   - Start with [DEPLOYMENT_GUIDE.md](./deployments/gcp/DEPLOYMENT_GUIDE.md)
   - Understand [ARCHITECTURE.md](./deployments/gcp/ARCHITECTURE.md)

2. **Prepare Infrastructure**
   - Create GCP project
   - Enable APIs
   - Create service account

3. **Configure Deployment**
   - Copy `terraform.tfvars.example`
   - Customize values
   - Review `terraform plan`

4. **Deploy**
   - Run `terraform apply`
   - Wait for completion
   - Verify outputs

5. **Test & Monitor**
   - Access Foundry at domain
   - Check monitoring dashboard
   - Verify alerts

6. **Optimize**
   - Monitor usage
   - Adjust scaling parameters
   - Apply CUDs for savings

---

## 📄 File Locations

| Document | Location |
|----------|----------|
| GCP Module Summary | `./GCP_MODULES_SUMMARY.md` |
| Index (This File) | `./GCP_INFRASTRUCTURE_INDEX.md` |
| Deployment README | `./deployments/gcp/README.md` |
| Deployment Guide | `./deployments/gcp/DEPLOYMENT_GUIDE.md` |
| Architecture Doc | `./deployments/gcp/ARCHITECTURE.md` |
| Quick Reference | `./deployments/gcp/QUICK_REFERENCE.md` |
| Configuration Template | `./deployments/gcp/terraform.tfvars.example` |
| Main Orchestration | `./deployments/gcp/main.tf` |
| Variables | `./deployments/gcp/variables.tf` |

---

## 🤝 Support Resources

- **GCP Documentation**: https://cloud.google.com/docs
- **Terraform Registry**: https://registry.terraform.io/providers/hashicorp/google
- **Foundry VTT**: https://foundryvtt.com
- **Cloudflare**: https://www.cloudflare.com

---

**Version**: 1.0
**Last Updated**: 2024-06-28
**Status**: Production-Ready ✅
**Terraform**: >= 1.5
**Google Cloud Provider**: >= 5.0

---

**🎉 Ready to Deploy?** → Start with [DEPLOYMENT_GUIDE.md](./deployments/gcp/DEPLOYMENT_GUIDE.md)

