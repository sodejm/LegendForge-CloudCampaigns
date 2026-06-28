# LegendForge on GCP - Quick Reference Guide

## Pre-Deployment Checklist

- [ ] GCP project created with billing enabled
- [ ] Required APIs enabled (see DEPLOYMENT_GUIDE.md)
- [ ] Terraform service account created and key downloaded
- [ ] Foundry VTT license key obtained
- [ ] Cloudflare tunnel token created
- [ ] Domain name ready with DNS management access
- [ ] Terraform and gcloud CLI installed

---

## Quick Start (5 Steps)

### 1. Clone/Navigate to Deployment

```bash
cd /path/to/LegendForge-CloudCampaigns/infrastructure/deployments/gcp
```

### 2. Configure Terraform

```bash
cp terraform.tfvars.example terraform.auto.tfvars
nano terraform.auto.tfvars

# Key values to update:
# - gcp_project_id
# - foundry_license_key
# - foundry_admin_key
# - cloudflare_tunnel_token
# - domain_name
# - admin_source_ranges (your IP)
```

### 3. Initialize & Plan

```bash
terraform init
terraform plan -out=tfplan
```

### 4. Apply Configuration

```bash
terraform apply tfplan
```

### 5. Finalize Setup

```bash
# Update DNS to point to load balancer IP
LB_IP=$(terraform output -raw load_balancer_ip)

# Wait 10-15 minutes for SSL certificate activation
# Then access: https://foundry.example.com
```

---

## Common Commands

### View Infrastructure Status

```bash
# List outputs
terraform output

# Check compute instances
gcloud compute instances list --filter="tags.items=foundry-compute"

# Check instance health
gcloud compute backend-services get-health foundry-legendforge-backend

# View database status
gcloud sql instances list
gcloud sql instances describe foundry-legendforge-db
```

### Monitor & Logs

```bash
# Real-time logs
gcloud logging read "resource.type=gce_instance" --stream

# View monitoring dashboard
DASHBOARD_ID=$(terraform output -raw monitoring_dashboard_id)
echo "https://console.cloud.google.com/monitoring/dashboards/custom/$DASHBOARD_ID"

# Check specific metric (CPU)
gcloud monitoring time-series list \
  --filter='metric.type="compute.googleapis.com/instance/cpu/utilization"'
```

### Database Operations

```bash
# Connect to database
gcloud sql connect foundry-legendforge-db --user=foundry_app

# Export database
gcloud sql export sql foundry-legendforge-db \
  gs://foundry-legendforge-backups-*/db-backup.sql \
  --database=foundry

# List backups
gcloud sql backups list --instance=foundry-legendforge-db

# Create on-demand backup
gcloud sql backups create --instance=foundry-legendforge-db
```

### Storage Operations

```bash
# List storage buckets
gsutil ls

# List backups
gsutil ls gs://foundry-legendforge-backups-*/

# Download backup
gsutil cp gs://foundry-legendforge-backups-*/backup.sql .

# Upload data
gsutil -m cp -r ./my-data/* gs://foundry-legendforge-data-*/
```

### Scaling

```bash
# Scale instances manually
gcloud compute instance-groups managed set-autoscaling foundry-legendforge-igm \
  --min-num-replicas=1 \
  --max-num-replicas=10 \
  --target-cpu-utilization=0.7 \
  --region=us-central1

# Update machine type (requires new instance group)
# Edit terraform.auto.tfvars: compute_machine_type
# Then: terraform apply

# Scale database
# Edit terraform.auto.tfvars: cloudsql_machine_type
# Then: terraform apply (requires downtime)
```

### Troubleshooting

```bash
# Check startup script output
gcloud compute instances get-serial-port-output INSTANCE_NAME

# SSH into instance (if admin IP is in whitelist)
gcloud compute ssh INSTANCE_NAME --zone=ZONE

# View firewall rules
gcloud compute firewall-rules list

# Check VPC network
gcloud compute networks list

# View IAM permissions
gcloud projects get-iam-policy legendforge

# Check secrets
gcloud secrets list

# Get secret value (sensitive)
gcloud secrets versions access latest --secret=foundry-legendforge-license-key
```

---

## Terraform Useful Commands

```bash
# Format code
terraform fmt -recursive

# Validate syntax
terraform validate

# Plan with output file
terraform plan -out=tfplan

# Apply from plan file
terraform apply tfplan

# Apply with auto-approval (careful!)
terraform apply -auto-approve

# Destroy infrastructure
terraform destroy

# Target specific resource (careful!)
terraform apply -target=module.compute

# Import existing resource
terraform import google_compute_instance.example \
  projects/PROJECT/zones/ZONE/instances/INSTANCE

# Refresh state
terraform refresh

# Show resource details
terraform state show module.compute.google_compute_instance_template.foundry

# Output specific value
terraform output load_balancer_ip
terraform output -raw load_balancer_ip
```

---

## Environment Variables

```bash
# Set GCP project
export GOOGLE_CLOUD_PROJECT=legendforge
gcloud config set project $GOOGLE_CLOUD_PROJECT

# Set credentials
export GOOGLE_APPLICATION_CREDENTIALS=~/terraform-key.json

# Set region (optional)
export GOOGLE_CLOUD_REGION=us-central1

# Set zone (optional)
export GOOGLE_COMPUTE_ZONE=us-central1-a

# Terraform variables via environment
export TF_VAR_gcp_project_id=legendforge
export TF_VAR_foundry_license_key=YOUR_KEY
```

---

## Cost Management

```bash
# Estimate costs
gcloud billing budgets create --billing-account=ACCOUNT \
  --display-name="Foundry Budget" \
  --budget-amount=500 \
  --threshold-rule=amount=400,percentage=80 \
  --threshold-rule=amount=450,percentage=90

# View current spending
gcloud billing accounts list
gcloud billing accounts describe ACCOUNT

# Export billing data
bq load --autodetect --source_format=CSV \
  billing.exports \
  gs://billing-bucket/export.csv

# Use pricing calculator
# https://cloud.google.com/products/calculator
```

---

## Backup & Restore

### Automated Backups

- **Cloud SQL**: Daily at 02:00 UTC, 30-day retention
- **Foundry Data**: Daily to Cloud Storage (via cron)
- **Media Assets**: Versioned with lifecycle policies

### Manual Backup

```bash
# Database
gcloud sql export sql foundry-legendforge-db \
  gs://foundry-legendforge-backups-*/manual-backup-$(date +%Y%m%d).sql \
  --database=foundry

# Foundry data
gsutil -m cp -r /opt/foundry/data/* \
  gs://foundry-legendforge-data-*/backup-$(date +%Y%m%d)/
```

### Restore

```bash
# From Cloud SQL backup
gcloud sql backups restore BACKUP_ID \
  --instance=foundry-legendforge-db

# From Cloud Storage export
gcloud sql import sql foundry-legendforge-db \
  gs://foundry-legendforge-backups-*/backup.sql \
  --database=foundry

# From Foundry data backup
gsutil -m cp -r \
  gs://foundry-legendforge-data-*/backup-DATE/* \
  /opt/foundry/data/
```

---

## SSL Certificate Management

```bash
# Check certificate status
gcloud compute ssl-certificates describe foundry-legendforge-cert

# List certificates
gcloud compute ssl-certificates list

# Create managed certificate (manual)
gcloud compute ssl-certificates create my-cert \
  --domains=foundry.example.com

# Renew certificate (automatic, no action needed)

# Check certificate expiry
gcloud compute ssl-certificates describe foundry-legendforge-cert \
  --format="value(managed.domainStatuses[0].domainName,certificate.expireTime)"
```

---

## Security Audit

```bash
# Check VPC security
gcloud compute firewall-rules list --filter="direction=INGRESS" --format=table

# Check service account permissions
gcloud projects get-iam-policy legendforge \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:*"

# Check secrets access
gcloud secrets get-iam-policy foundry-legendforge-license-key

# Check storage bucket permissions
gsutil iam ch serviceAccount:foundry-compute@legendforge.iam.gserviceaccount.com:objectAdmin \
  gs://foundry-legendforge-data-*/

# Audit Cloud SQL configuration
gcloud sql instances describe foundry-legendforge-db --format=json
```

---

## Performance Optimization

### Increase Instance Resources

```hcl
# In terraform.auto.tfvars
compute_machine_type = "n2-standard-4"  # From 2 to 4 vCPU
```

### Increase Database Resources

```hcl
cloudsql_machine_type = "db-custom-4-16384"  # From 2 to 4 vCPU
```

### Adjust Auto-Scaling

```hcl
min_instances = 3              # More warm instances
max_instances = 10             # Higher ceiling
cpu_target_utilization = 0.6   # Scale earlier
```

### Enable Advanced Caching

```bash
# In modules/gcp-loadbalancer/main.tf
# Uncomment: enable_adaptive_protection = true
```

---

## Disaster Recovery Test

```bash
# Simulate instance failure
gcloud compute instances stop INSTANCE_NAME

# Monitor auto-healing
gcloud compute instance-groups managed wait-until \
  foundry-legendforge-igm \
  --max-wait=300 \
  --operation-timeout=300

# Verify new instance started
gcloud compute instances list --filter="tags.items=foundry-compute"

# Test database failover
gcloud sql instances failover foundry-legendforge-db

# Check failover logs
gcloud logging read "resource.type=cloudsql_database" --limit=20
```

---

## Cleanup (Destructive!)

```bash
# Remove everything (careful!)
terraform destroy

# Remove specific resource
terraform destroy -target=module.loadbalancer

# Backup before destroying
gsutil -m cp -r gs://foundry-legendforge-data-*/* ./foundry-backup/

# Then destroy
terraform destroy
```

---

## Emergency Procedures

### Recover from Lost Database

```bash
# If primary database is corrupted:
1. gcloud sql instances failover foundry-legendforge-db
2. Wait 5 minutes
3. Verify: gcloud sql instances describe foundry-legendforge-db
4. Restore from backup if needed
```

### Recover from Lost Instances

```bash
# Auto-healing should replace instances automatically
# If not:
1. Manually delete unhealthy instances
2. Instance group will launch replacements
3. Monitor: gcloud compute instance-groups managed list
```

### Recover from Lost Data

```bash
# Restore from Cloud Storage backup
gsutil cp gs://foundry-legendforge-data-*/backup.tar.gz .
tar -xzf backup.tar.gz -C /opt/foundry/data

# Restore Foundry database
gcloud sql import sql foundry-legendforge-db \
  gs://foundry-legendforge-backups-*/backup.sql \
  --database=foundry
```

---

## Support & Help

- **Terraform Docs**: https://www.terraform.io/docs
- **GCP Docs**: https://cloud.google.com/docs
- **Google Cloud CLI**: `gcloud help`
- **Foundry VTT Support**: https://foundryvtt.com/support
- **Community Forums**: https://forums.foundryvtt.com

---

**Last Updated**: 2024-06-28
