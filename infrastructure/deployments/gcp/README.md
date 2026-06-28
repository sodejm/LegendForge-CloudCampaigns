# LegendForge on Google Cloud Platform

**Production-ready Terraform infrastructure for running LegendForge on Google Cloud Platform.**

---

## 📋 Quick Links

- **[Deployment Guide](./DEPLOYMENT_GUIDE.md)** - Step-by-step deployment instructions
- **[Architecture](./ARCHITECTURE.md)** - Detailed system design and components
- **[Quick Reference](./QUICK_REFERENCE.md)** - Common commands and operations
- **[Configuration Example](./terraform.tfvars.example)** - Sample configuration

---

## 🚀 Features

### ✅ High Availability
- Multi-zone instance groups (3 availability zones)
- Auto-healing instances
- Cloud SQL regional HA with automatic failover
- Global load balancer with health checks

### ✅ Auto-Scaling
- CPU-based horizontal scaling (2-5 instances)
- Optional memory-based scaling
- Automatic scale-down during idle periods

### ✅ Security
- VPC with private networking
- Firewall rules with least-privilege access
- Cloud Armor DDoS protection and WAF
- Secret Manager for sensitive data
- Cloud KMS encryption
- IAM service accounts with minimal permissions

### ✅ Data Protection
- Cloud SQL automated backups (30-day retention)
- Point-in-time recovery (7 days)
- Cloud Storage with versioning and lifecycle policies
- Encrypted data at rest (Cloud KMS)
- Encrypted data in transit (TLS/SSL)

### ✅ Performance
- Global HTTPS load balancer with anycast routing
- Cloud CDN for static asset caching
- Session affinity for WebSocket connections
- Connection pooling and circuit breakers

### ✅ Monitoring & Observability
- Cloud Monitoring dashboards (CPU, memory, network, database)
- Automated alerting policies (CPU, memory, health, errors)
- Cloud Logging with centralized log aggregation
- Uptime checks from 3 global regions
- Error tracking and reporting

### ✅ Cost Optimization
- Auto-scaling to prevent over-provisioning
- Cloud Storage lifecycle policies (archive old backups)
- Committed Use Discounts support
- Detailed cost breakdowns

---

## 📊 Cost Estimation

**Monthly costs (approximate, based on us-central1):**

| Setup | Small (5-10 players) | Medium (25 players) | Large (50+ players) |
|-------|---------------------|---------------------|---------------------|
| Compute | $131 | $262 | $524 |
| Database | $180 | $240 | $400 |
| Storage | $20-30 | $50 | $100+ |
| Load Balancer | $20 | $20 | $20 |
| Monitoring | $0 | $0 | $0 |
| **Total** | **$350-370/mo** | **$570-600/mo** | **$1,040+/mo** |

*With 1-year Committed Use Discounts: ~25% savings*

---

## 🔧 Prerequisites

### GCP Setup
- GCP project with billing enabled
- Terraform service account with Editor role
- Required APIs enabled (compute, SQL, storage, IAM, monitoring, logging, secrets, KMS)

### Local Tools
- Terraform >= 1.5
- Google Cloud SDK (gcloud CLI)
- Text editor (VS Code, nano, vim, etc.)

### Foundry VTT
- Foundry VTT license key from https://foundryvtt.com
- Admin password for initial setup
- Cloudflare account (free tier sufficient)
- Domain name with DNS management access

---

## ⚡ Quick Start

### 1. Setup GCP

```bash
# Create project
gcloud projects create legendforge --name="LegendForge"
gcloud config set project legendforge

# Enable APIs
gcloud services enable compute.googleapis.com sqladmin.googleapis.com \
  storage-api.googleapis.com iam.googleapis.com monitoring.googleapis.com \
  logging.googleapis.com secretmanager.googleapis.com cloudkms.googleapis.com

# Create Terraform service account
gcloud iam service-accounts create terraform --display-name="Terraform"
gcloud projects add-iam-policy-binding legendforge \
  --member="serviceAccount:terraform@legendforge.iam.gserviceaccount.com" \
  --role="roles/editor"
gcloud iam service-accounts keys create ~/terraform-key.json \
  --iam-account=terraform@legendforge.iam.gserviceaccount.com

export GOOGLE_APPLICATION_CREDENTIALS=~/terraform-key.json
```

### 2. Configure Terraform

```bash
cd deployments/gcp
cp terraform.tfvars.example terraform.auto.tfvars

# Edit configuration
nano terraform.auto.tfvars
# Set: gcp_project_id, foundry_license_key, cloudflare_tunnel_token, etc.
```

### 3. Deploy

```bash
terraform init
terraform plan
terraform apply
```

### 4. Finalize

```bash
# Get load balancer IP
terraform output load_balancer_ip

# Update DNS to point to this IP
# Wait 10-15 minutes for SSL certificate activation
# Access: https://foundry.example.com
```

---

## 📁 Directory Structure

```
deployments/gcp/
├── main.tf                          # Main deployment orchestration
├── variables.tf                     # Deployment configuration variables
├── terraform.tfvars.example         # Configuration example
├── DEPLOYMENT_GUIDE.md              # Step-by-step deployment guide
├── ARCHITECTURE.md                  # Detailed architecture & design
├── QUICK_REFERENCE.md               # Common commands & operations
├── README.md                        # This file
└── templates/
    └── cloud-init.yaml              # Startup script for instances
```

```
modules/
├── gcp-vpc/                         # VPC networking module
├── gcp-iam/                         # IAM roles & service accounts
├── gcp-cloudsql/                    # Cloud SQL database
├── gcp-storage/                     # Cloud Storage buckets
├── gcp-compute/                     # Compute instances & auto-scaling
├── gcp-loadbalancer/                # Load balancer & Cloud Armor
├── gcp-monitoring/                  # Monitoring, logging, & alerts
└── gcp-secrets/                     # Secret Manager & KMS
```

---

## 📚 Module Overview

### VPC Module (`gcp-vpc`)
- Creates VPC network with subnets
- Configures Cloud NAT for outbound internet
- Sets up firewall rules (least-privilege)
- Enables VPC Flow Logs

**Inputs**: Project name, regions, CIDR ranges, admin IPs
**Outputs**: VPC ID, subnet IDs, router ID

### IAM Module (`gcp-iam`)
- Creates 5 service accounts (compute, database, storage, monitoring, secrets)
- Defines custom Foundry role with minimal permissions
- Sets up IAM bindings per resource

**Inputs**: Project ID, project name
**Outputs**: Service account emails

### Cloud SQL Module (`gcp-cloudsql`)
- Creates PostgreSQL database instance (regional HA)
- Configures automated backups and PITR
- Creates database and application users
- Optional: Read replicas for disaster recovery

**Inputs**: Database config, VPC details, users
**Outputs**: Connection names, database credentials

### Cloud Storage Module (`gcp-storage`)
- Creates 4 storage buckets (data, media, backups, logs)
- Configures versioning and lifecycle policies
- Sets up access control and encryption
- Implements audit logging

**Inputs**: Project name, service account emails, encryption keys
**Outputs**: Bucket names and URLs

### Compute Module (`gcp-compute`)
- Creates instance template with cloud-init startup script
- Creates managed instance group across 3 zones
- Configures auto-scaling and health checks
- Implements auto-healing

**Inputs**: Machine type, disk sizes, startup script, network config
**Outputs**: Instance group ID, template ID, health check ID

### Load Balancer Module (`gcp-loadbalancer`)
- Creates global HTTPS load balancer
- Configures SSL/TLS termination
- Implements Cloud CDN for static assets
- Sets up Cloud Armor with DDoS protection and WAF

**Inputs**: Domain name, instance group, health check
**Outputs**: Load balancer IP, certificate details

### Monitoring Module (`gcp-monitoring`)
- Creates monitoring dashboard with key metrics
- Configures alert policies (CPU, memory, database, uptime)
- Sets up uptime checks from 3 global regions
- Creates log-based metrics for error tracking

**Inputs**: Instance group name, database name, notification channels
**Outputs**: Dashboard ID, alert policy IDs

### Secrets Module (`gcp-secrets`)
- Creates Secret Manager secrets for all sensitive data
- Configures Cloud KMS encryption
- Sets up IAM access for service accounts
- Manages secret versions and rotation

**Inputs**: Passwords, keys, tokens (all sensitive)
**Outputs**: Secret IDs, KMS key ID

---

## 🔐 Security Best Practices

1. **Network Security**
   - Restrict SSH to admin IPs only
   - Use Cloud VPN or Cloud Interconnect for admin access
   - Enable VPC Flow Logs for audit trails

2. **Access Control**
   - Use service accounts with minimal permissions
   - Enable Workload Identity if using GKE
   - Regular IAM audits

3. **Data Protection**
   - Enable Cloud KMS for database and storage encryption
   - Use Secret Manager for all sensitive data
   - Regular automated backups with point-in-time recovery

4. **Application Security**
   - Keep Docker images patched (use digest-pinned images)
   - Enable Shielded VM (secure boot, vTPM, integrity monitoring)
   - Use Cloud Armor for DDoS/WAF protection

5. **Monitoring & Compliance**
   - Enable Cloud Audit Logs for compliance
   - Set up alerting for security events
   - Regular security assessments

---

## 🎯 Common Workflows

### Scale Up for Campaign Session
```bash
# Temporary increase for game night
terraform apply -var="max_instances=10" -var="cpu_target_utilization=0.5"

# Restore after session
terraform apply -var="max_instances=5" -var="cpu_target_utilization=0.7"
```

### Backup Before Major Update
```bash
gcloud sql export sql foundry-legendforge-db \
  gs://foundry-legendforge-backups-*/pre-update-backup.sql \
  --database=foundry
```

### Monitor Deployment
```bash
# Real-time logs
gcloud logging read --stream \
  "resource.type=gce_instance AND resource.labels.instance_group_manager_name=foundry-legendforge-igm"

# View dashboard
DASHBOARD_ID=$(terraform output -raw monitoring_dashboard_id)
open "https://console.cloud.google.com/monitoring/dashboards/custom/$DASHBOARD_ID"
```

### Update Configuration
```bash
# Edit configuration
nano terraform.auto.tfvars

# Preview changes
terraform plan

# Apply changes (most won't cause downtime)
terraform apply
```

---

## ❓ FAQ

### Q: Can I run this in a different region?
**A**: Yes! Change `primary_region` in `terraform.auto.tfvars` to any GCP region (e.g., `europe-west1`, `asia-northeast1`).

### Q: How do I add more players?
**A**: Increase `max_instances` and/or upgrade machine types. Auto-scaling will handle load.

### Q: What if I need more storage?
**A**: Cloud Storage is unlimited. Persistent disk size is configurable in `data_disk_size_gb`.

### Q: Can I use this for production?
**A**: Yes! This is designed for production with HA, backups, monitoring, and security best practices.

### Q: How much does this cost?
**A**: $350-400/month for small campaigns, $600/month for medium, $1000+/month for large. See cost table above.

### Q: Can I upgrade database later?
**A**: Yes, but it requires brief downtime. Edit `cloudsql_machine_type` and apply.

### Q: How do I migrate from another provider?
**A**: Export database backup from old provider, restore to Cloud SQL. Terraform imports existing resources.

### Q: What's the recovery time if something fails?
**A**: < 5 minutes for compute instances, < 1 minute for database failover.

---

## 📞 Support

- **Deployment Issues**: See DEPLOYMENT_GUIDE.md troubleshooting section
- **Architecture Questions**: See ARCHITECTURE.md
- **Common Operations**: See QUICK_REFERENCE.md
- **GCP Docs**: https://cloud.google.com/docs
- **Terraform Docs**: https://registry.terraform.io/providers/hashicorp/google
- **Foundry VTT**: https://foundryvtt.com

---

## 📄 License

This Terraform configuration is provided for LegendForge deployment on Google Cloud Platform.

---

**Created**: 2024-06-28
**Terraform**: >= 1.5
**Google Cloud Provider**: >= 5.0
**Status**: Production-Ready ✅

