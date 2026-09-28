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
- ✓ Private Foundry VMs with IAP and OS Login for administrator SSH

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
     iap.googleapis.com \
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

### 4. Administrator Access with IAP and OS Login

The standard deployment's Foundry VMs have no external IPs. Before deployment or
migration, enable the IAP API as above and have an IAM administrator grant trusted
operators the following permissions. Terraform does not automatically grant
administrator access.

- **IAP-secured Tunnel User / Tunnel Resource Accessor**
  (`roles/iap.tunnelResourceAccessor`) on the intended VM's IAP tunnel resource,
  or at project scope when access to the managed group's replacement VMs is
  required. Restrict the grant to TCP port 22 with an IAM condition where appropriate.
- **Compute OS Admin Login** (`roles/compute.osAdminLogin`) on the intended VMs,
  or at project scope for managed-group administration. This supplies OS Login
  access with administrative privileges. Instance-scoped grants also require
  `compute.projects.get` at project scope for the gcloud CLI.
- **Service Account User** (`roles/iam.serviceAccountUser`) on the service
  account attached to the Foundry VMs, rather than on every project service account.
- The gcloud CLI also needs `compute.instances.get`, `compute.instances.list`,
  and `compute.projects.get`; provide these through a scoped custom role or an
  existing appropriate role. Operators outside the project's organization also
  need `roles/compute.osLoginExternalUser` on that organization.

See Google's [IAP TCP forwarding requirements](https://docs.cloud.google.com/iap/docs/using-tcp-forwarding)
and [OS Login setup](https://docs.cloud.google.com/compute/docs/oslogin/set-up-oslogin).
Confirm that the grants cover replacement VMs before applying a managed-group
update; grants tied only to an old instance will not cover a new instance.

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
admin_source_ranges       = ["35.235.240.0/20"] # IAP TCP forwarding
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

**Existing campaigns:** removing the external-IP configuration changes the
instance template and can replace managed VMs. Before applying, review the
replacement actions and rolling-update behavior in the plan, schedule a
maintenance window, and verify a current off-host world backup and a tested
restore procedure. Retained data disks alone do not establish safe reattachment:
replacement VMs may receive new disks. Record how to restore the world to a
replacement VM and how to recover if startup or player access fails. Restore and
verify campaign data before resuming play. Review any rollback plan as another
potential replacement, including the exposure caused by restoring public IPs.

For both new deployments and migrations, complete the IAP/OS Login prerequisites
and update explicit `admin_source_ranges` overrides to include
`35.235.240.0/20` before removing the external IPs. An office/home public CIDR
alone does not permit IAP tunnel traffic.

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

When upgrading an existing deployment to the shared HTTP/HTTPS frontend, review
the Terraform plan before applying. The previously unused regional address is
replaced by a global address, and both forwarding rules move from their separate
ephemeral addresses to that global address. This can interrupt ingress during the
update and changes the DNS target. Schedule a maintenance window, update the A
record to the new `load_balancer_ip`, and allow DNS and certificate provisioning
to complete before testing player access.

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

# HTTP must return 301 with the same host, path, and query in Location
curl -sS -D - -o /dev/null 'http://foundry.example.com/join?world=campaign'
# Expected: Location: https://foundry.example.com/join?world=campaign
# No Foundry content or application Set-Cookie header should be returned over HTTP
```

After the certificate is ACTIVE, verify HTTPS login in a browser, load a world
and its static assets, and confirm Socket.IO/WebSocket play works without mixed
content errors. The local mocked Terraform tests check routing configuration;
they do not establish deployed browser behavior. Enable HSTS only after these
HTTPS checks succeed.

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

### 9.1 Use IAP and OS Login

For an existing campaign, review the [replacement and backup precautions](#32-apply-configuration)
before applying this change.

The standard deployment and VPC module default SSH ingress to IAP's source range.
Keep that range in any explicit `terraform.auto.tfvars` override:

```hcl
admin_source_ranges = ["35.235.240.0/20"]
```

Additional private administrator CIDRs can remain in the list when a separate
private access path requires them. Connect using OS Login through IAP:

```bash
gcloud compute ssh INSTANCE_NAME --project=PROJECT_ID --zone=ZONE --tunnel-through-iap
```

Use an operator identity with the [required permissions](#4-administrator-access-with-iap-and-os-login).
The VMs have no external IPs, and both backend firewall rules admit TCP 30030 only
from `35.191.0.0/16` and `130.211.0.0/22`, following Google's
[load balancer firewall requirements](https://docs.cloud.google.com/load-balancing/docs/firewall-rules).
The existing HTTPS listener, HTTP redirect, health checks, internal rules, Cloud
NAT, and Private Google Access are retained. Outbound startup downloads use NAT;
Google API access, including Secret Manager, retains Private Google Access.

#### Private-origin deployment acceptance

After an approved test-environment deployment, record evidence for all of these
checks before treating [#142](https://github.com/sodejm/LegendForge-CloudCampaigns/issues/142)
as complete:

- List every Foundry VM's network interfaces and confirm there are no external
  IPv4 or IPv6 addresses, including rolling-update replacements. For example:
  `gcloud compute instances list --project=PROJECT_ID --filter="tags.items=foundry-compute" --format="json(name,zone,networkInterfaces)"`.
- Confirm both backend rules retain only the documented source ranges and that
  the private origin cannot be reached directly from the Internet on TCP 30030.
- Verify healthy load balancer backends and successful startup downloads through
  NAT, plus successful Secret Manager reads from the private VMs. Inspect startup
  logs and test outbound access from an authorized IAP session.
- Verify HTTPS sign-in, asset loading, WebSocket play, and the HTTP-to-HTTPS redirect.
- Verify authorized IAP SSH succeeds and an identity without the required tunnel
  or OS Login permissions cannot obtain administrator access.
- For migrated campaigns, restore and verify the world and assets using the
  documented off-host backup procedure.

Local mock plans and a merged PR do not establish this live acceptance. Keep the
issue open until these checks pass. Cloud Armor attachment (#145), broader SSH
hardening, and low-cost deployments are separate work.

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
