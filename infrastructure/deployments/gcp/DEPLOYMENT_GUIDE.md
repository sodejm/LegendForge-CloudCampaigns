# LegendForge on Google Cloud Platform - Deployment Guide

## Overview

This guide provides step-by-step instructions to deploy a production-ready LegendForge infrastructure on Google Cloud Platform (GCP) using Terraform.

**Key Features:**
- ✓ Highly Available (multi-zone instance groups with auto-healing)
- ✓ Auto-scaling based on CPU and memory usage
- ✓ Cloud SQL PostgreSQL with HA failover
- ✓ Cloud Storage for backups and media
- ✓ Global HTTPS load balancer with Cloud CDN
- ✓ Cloud Armor DDoS protection
- ✓ Comprehensive monitoring and alerting
- ✓ Secret Manager for secure credential storage
- ✓ Cloud NAT for private outbound internet access

---

## Prerequisites

### 1. GCP Account Setup

1. **Create a GCP Project**
   ```bash
   gcloud projects create legendforge --name="LegendForge"
   gcloud config set project legendforge
   ```

2. **Enable Required APIs**
   ```bash
   gcloud services enable \
     compute.googleapis.com \
     sqladmin.googleapis.com \
     storage-api.googleapis.com \
     cloudresourcemanager.googleapis.com \
     iam.googleapis.com \
     monitoring.googleapis.com \
     logging.googleapis.com \
     secretmanager.googleapis.com \
     cloudkms.googleapis.com \
     servicenetworking.googleapis.com
   ```

3. **Create a GCP Service Account for Terraform**
   ```bash
   gcloud iam service-accounts create terraform \
     --display-name="Terraform Service Account"
   
   gcloud projects add-iam-policy-binding legendforge \
     --member="serviceAccount:terraform@legendforge.iam.gserviceaccount.com" \
     --role="roles/editor"
   
   gcloud iam service-accounts keys create ~/terraform-key.json \
     --iam-account=terraform@legendforge.iam.gserviceaccount.com
   ```

4. **Set Environment Variable**
   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS=~/terraform-key.json
   ```

### 2. Local Requirements

- Terraform >= 1.5
- Google Cloud SDK (gcloud CLI)
- Docker (optional, for local testing)
- A domain name with DNS management access

### 3. Foundry VTT Requirements

- **Foundry License Key**: Get from your Foundry account at https://foundryvtt.com
- **Admin Password**: Secure password for initial Foundry setup
- **Cloudflare Account**: Free tier is sufficient (for Cloudflare Tunnel)

---

## Step 1: Cloudflare Tunnel Setup (Required)

Since we're using Cloudflare Tunnel for ingress, setup is required BEFORE deployment.

### 1.1 Create Cloudflare Tunnel

1. Go to Cloudflare Zero Trust: https://one.dash.cloudflare.com
2. Navigate to **Access > Tunnels**
3. Click **Create a tunnel**
4. Name it: `foundry-vtt`
5. Choose **Docker** as the connector type (we'll use it on Compute Engine)
6. Copy the tunnel token (you'll need this for `cloudflare_tunnel_token`)

### 1.2 Configure DNS Route

1. In the tunnel settings, add a public hostname:
   - Subdomain: `foundry`
   - Domain: `example.com`
   - Service: `HTTP` -> `localhost:30030`
2. Save the configuration

---

## Step 2: Prepare Terraform Configuration

### 2.1 Clone/Navigate to Deployment Directory

```bash
cd /path/to/LegendForge-CloudCampaigns/infrastructure/deployments/gcp
```

### 2.2 Create Configuration File

```bash
cp terraform.tfvars.example terraform.auto.tfvars
```

### 2.3 Edit Configuration

```bash
# Open with your editor
nano terraform.auto.tfvars
```

**Key values to set:**

```hcl
gcp_project_id            = "your-gcp-project-id"
foundry_hostname          = "foundry.example.com"
domain_name               = "foundry.example.com"
foundry_license_key       = "YOUR_LICENSE_KEY"
foundry_admin_key         = "YOUR_ADMIN_PASSWORD"
cloudflare_tunnel_token   = "YOUR_TUNNEL_TOKEN"
database_password         = "YOUR_DB_PASSWORD" # Generate a strong password
admin_source_ranges       = ["YOUR_IP/32"]     # Your office/home IP
```

### 2.4 Validate Syntax

```bash
terraform fmt -recursive ../..
terraform validate
```

---

## Step 3: Deploy Infrastructure

### 3.1 Plan Deployment

```bash
terraform plan -out=tfplan
```

Review the output carefully. You should see:
- VPC with subnets
- IAM service accounts
- Cloud SQL instance
- Cloud Storage buckets
- Compute instances (in instance group)
- Load balancer
- Monitoring dashboards
- Secret Manager secrets

### 3.2 Apply Configuration

```bash
terraform apply tfplan
```

This will take 10-15 minutes to complete. Watch for:
- ✓ VPC resources creation
- ✓ Service account setup
- ✓ Cloud SQL provisioning (longest step, ~5-10 min)
- ✓ Storage buckets
- ✓ Compute instances launching
- ✓ Load balancer configuration
- ✓ SSL certificate provisioning (may take a few minutes)

### 3.3 Capture Outputs

```bash
terraform output
```

Save these values:
- `load_balancer_ip`: Static IP of your load balancer
- `database_connection_name`: For SQL Proxy connections
- `database_private_ip`: Internal database IP
- `instance_group_id`: For scaling operations

---

## Step 4: Post-Deployment Configuration

### 4.1 Update DNS

Point your domain to the load balancer IP:

```bash
# Get the load balancer IP
LB_IP=$(terraform output -raw load_balancer_ip)

# Add DNS record (A record) pointing to this IP
# In your DNS provider:
# foundry.example.com A $LB_IP
```

### 4.2 Verify SSL Certificate

Google Cloud automatically provisions an SSL certificate. Check status:

```bash
gcloud compute ssl-certificates list
gcloud compute ssl-certificates describe foundry-legendforge-cert
```

Wait for status to become "ACTIVE" (usually 10-15 minutes after DNS propagation).

### 4.3 Verify Instances Are Healthy

```bash
# Check instance group
gcloud compute instance-groups managed list

# Check instances
gcloud compute instances list --filter="tags.items=foundry-compute"

# Check instance health
gcloud compute backend-services get-health foundry-legendforge-backend
```

### 4.4 Test Load Balancer

```bash
# Get load balancer IP
LB_IP=$(terraform output -raw load_balancer_ip)

# Test HTTPS connection
curl -I https://foundry.example.com

# Should return 200 or redirect to Foundry login
```

---

## Step 5: Access Foundry VTT

### 5.1 First Access

Navigate to: `https://foundry.example.com`

You should see:
1. Foundry login screen
2. Click "Create Admin Account"
3. Enter your admin password (from `foundry_admin_key`)
4. Create your world and enjoy!

### 5.2 Database Connection (Optional)

If you want to connect directly to the database:

```bash
# Using Cloud SQL Proxy
gcloud sql connect $(terraform output -raw database_instance_name) \
  --user=foundry_app

# Or get connection details
terraform output database_connection_name
```

---

## Step 6: Monitoring & Alerts

### 6.1 View Monitoring Dashboard

```bash
DASHBOARD_ID=$(terraform output -raw monitoring_dashboard_id)
echo "Dashboard: https://console.cloud.google.com/monitoring/dashboards/custom/$DASHBOARD_ID"
```

### 6.2 Configure Alert Notifications

To receive alerts via email/Slack:

```bash
# Create a notification channel
gcloud alpha monitoring channels create \
  --display-name="Foundry Alerts" \
  --type=email \
  --channel-labels=email_address=your-email@example.com

# Get the channel ID and add to terraform.tfvars
gcloud alpha monitoring channels list
```

### 6.3 Check Logs

```bash
# View recent logs
gcloud logging read "resource.type=gce_instance AND resource.labels.instance_group_manager_name=foundry-legendforge-igm" \
  --limit=50 \
  --format=json

# Stream logs
gcloud logging read --stream \
  "resource.type=gce_instance AND resource.labels.instance_group_manager_name=foundry-legendforge-igm"
```

---

## Step 7: Backups & Maintenance

### 7.1 Automatic Backups

Backups are automatically configured for:
- **Cloud SQL**: Daily automated backups (retention: 30 days)
- **Foundry Data**: Daily backups to Cloud Storage

Check backup status:

```bash
# List Cloud SQL backups
gcloud sql backups list --instance=foundry-legendforge-db

# List backup objects in Cloud Storage
gsutil ls -r gs://$(terraform output -raw foundry_backups_bucket)/
```

### 7.2 Manual Database Backup

```bash
# Create on-demand backup
gcloud sql backups create \
  --instance=foundry-legendforge-db

# Export to Cloud Storage
gcloud sql export sql foundry-legendforge-db \
  gs://$(terraform output -raw foundry_backups_bucket)/manual-backup-$(date +%Y%m%d_%H%M%S).sql \
  --database=foundry
```

### 7.3 Restore from Backup

```bash
# Restore from Cloud SQL backup
gcloud sql backups restore BACKUP_ID \
  --instance=foundry-legendforge-db

# Or restore from Cloud Storage
gcloud sql import sql foundry-legendforge-db \
  gs://your-backup-bucket/backup.sql \
  --database=foundry
```

---

## Step 8: Scaling & Cost Optimization

### 8.1 Adjust Auto-Scaling

Edit `terraform.auto.tfvars`:

```hcl
min_instances = 1              # Minimum replicas
max_instances = 10             # Maximum replicas
cpu_target_utilization = 0.7   # Target CPU percentage
```

Re-apply:

```bash
terraform apply
```

### 8.2 Update Machine Types

To upgrade compute instances:

```hcl
# In terraform.auto.tfvars
compute_machine_type = "n2-standard-4"  # Upgrade from n2-standard-2
```

### 8.3 Committed Use Discounts

Enable cost savings with CUDs in GCP Console:
1. Compute Engine > Committed Use Discounts
2. Recommended discounts based on your usage
3. Purchase 1-year or 3-year commitments for 25-70% savings

---

## Step 9: Security Hardening

### 9.1 Restrict SSH Access

Edit `terraform.auto.tfvars`:

```hcl
# Only allow SSH from your office/home IP
admin_source_ranges = ["203.0.113.0/32"]
```

### 9.2 Enable VPC Service Controls (Optional)

Prevent data exfiltration by creating access boundaries in GCP Console.

### 9.3 Review IAM Permissions

```bash
gcloud projects get-iam-policy legendforge
```

Ensure only authorized service accounts have necessary permissions.

### 9.4 Enable Cloud Armor Rules

Cloud Armor is already enabled with:
- Rate limiting (100 requests/minute per IP)
- SQL injection detection
- XSS detection
- DDoS protection

To add geo-blocking, uncomment in `modules/gcp-loadbalancer/main.tf`.

---

## Troubleshooting

### Instances Not Starting

```bash
# Check instance serial logs
gcloud compute instances get-serial-port-output INSTANCE_NAME

# Check startup script output
gcloud compute instances describe INSTANCE_NAME --zone=ZONE
```

### DNS Not Resolving

```bash
# Check DNS propagation
nslookup foundry.example.com

# Check if record exists
dig foundry.example.com A
```

### SSL Certificate Not Active

- Check: `gcloud compute ssl-certificates describe foundry-legendforge-cert`
- DNS must propagate for certificate activation (typically 10-15 minutes)

### Load Balancer Not Routing Traffic

```bash
# Check backend health
gcloud compute backend-services get-health foundry-legendforge-backend

# Check health check
gcloud compute health-checks describe foundry-legendforge-health-check
```

### Database Connection Issues

```bash
# Test Cloud SQL connection
gcloud sql connect foundry-legendforge-db --user=foundry_app

# Check Cloud SQL proxy logs
gcloud logging read "resource.type=cloudsql_database"
```

---

## Cleanup & Destruction

### ⚠️ WARNING: This will delete ALL resources

```bash
terraform destroy
```

**Before destroying:**
1. Export important data from Foundry
2. Take a final database backup
3. Download backups from Cloud Storage
4. Ensure no active campaigns are in progress

---

## Cost Estimation

### Monthly Cost Breakdown (Approximate)

For `n2-standard-2` compute with minimum setup:

| Service | Quantity | Cost/Month |
|---------|----------|-----------|
| Compute Engine (2 instances × $0.09/hour) | 1,460 hours | $131 |
| Cloud SQL (db-custom-2-7680, HA) | 1 instance | $180 |
| Cloud Storage (data + backups, 1TB) | 1,024 GB | $20 |
| Load Balancer & CDN | 1 setup | $20-50 |
| Monitoring & Logging | Included | $0 |
| **Total (Estimated)** | | **$350-400** |

**To save costs:**
- Use `e2-standard-2` instead of `n2-standard-2`
- Reduce `max_instances` from 5 to 3
- Use COLDLINE storage for backups
- Enable Committed Use Discounts (1-year: ~25% savings)

---

## Advanced Configuration

### Enable Multi-Region HA

For disaster recovery across regions:

```hcl
enable_multi_region = true
secondary_region    = "europe-west1"
```

This adds:
- Cloud SQL read replica in secondary region
- Failover capability
- Better latency for European players

### Enable Memory-Based Autoscaling

```hcl
enable_memory_autoscaling = true
```

### Custom Firewall Rules

Edit `modules/gcp-vpc/main.tf` to add additional rules for:
- Specific IPs
- Different ports
- Third-party integrations

---

## Support & Resources

- **GCP Documentation**: https://cloud.google.com/docs
- **Foundry VTT**: https://foundryvtt.com
- **Terraform GCP Provider**: https://registry.terraform.io/providers/hashicorp/google
- **Cloudflare Tunnel**: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/
- **GCP Pricing Calculator**: https://cloud.google.com/products/calculator

---

## License

This Terraform configuration is provided as-is for LegendForge deployment.

---

**Last Updated**: 2024-06-28
**Terraform Version**: >= 1.5
**Google Cloud Provider**: >= 5.0
