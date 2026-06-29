# Production AWS Infrastructure for Foundry VTT

This directory contains production-ready Terraform infrastructure for deploying Foundry VTT on AWS with high availability, security, and comprehensive monitoring.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        CloudFront CDN                        │
│                   (Static Assets & Caching)                  │
└────────────────────────────┬────────────────────────────────┘
                             │
┌────────────────────────────┴────────────────────────────────┐
│                   Route53 (DNS)                              │
│                  (Health Checks & DNS)                       │
└────────────────────────────┬────────────────────────────────┘
                             │
┌────────────────────────────┴────────────────────────────────┐
│            Application Load Balancer (Multi-AZ)              │
│                  (SSL/TLS Termination)                       │
└────┬──────────────────────────────┬───────────────────────┘
     │                              │
┌────▼──────────────────┐  ┌──────▼─────────────────────┐
│    Auto Scaling Group │  │                            │
│ (Min: 2, Max: 4)      │  │  EC2 Instances (Foundry)   │
│                       │  │  - Docker Container        │
│ AZ-1 (Private)        │  │  - CloudFlare Tunnel       │
└───────────────────────┘  └────────────────────────────┘
                                    │
┌────┬──────────────────────────────┴───────────────────────┐
│    │                                                       │
│    └─────────────────────┬─────────────────────────────┐  │
│                          │                             │  │
│  ┌──────────────────────▼──────────────┐  ┌──────────▼──┐ │
│  │  Multi-AZ RDS PostgreSQL            │  │  S3 Buckets │ │
│  │  - Primary + Standby                │  │  - Data     │ │
│  │  - Automated Backups                │  │  - Assets   │ │
│  │  - Enhanced Monitoring              │  │  - Logs     │ │
│  └─────────────────────────────────────┘  └─────────────┘ │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start

### Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.0 installed
3. **AWS CLI** configured with credentials
4. **Route53 Zone** for your domain
5. **Foundry VTT** license key
6. **Cloudflare Tunnel** token (optional, for secure ingress)

### Deployment Steps

#### 1. Prepare Configuration

```bash
# Copy template files
cp terraform.tfvars.example terraform.tfvars
cp ../aws/secrets.tfvars.example ../aws/secrets.tfvars

# Edit configuration
vim terraform.tfvars
vim secrets.tfvars
```

#### 2. Configure Terraform Backend (Recommended)

```bash
# Create S3 bucket for state
aws s3 mb s3://my-foundry-terraform-state --region us-east-1
aws s3api put-bucket-versioning --bucket my-foundry-terraform-state --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

Then uncomment the backend block in `main.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "my-foundry-terraform-state"
    key            = "foundry/aws/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

#### 3. Initialize Terraform

```bash
terraform init
```

#### 4. Plan Deployment

```bash
terraform plan -out=tfplan
```

Review the output to ensure everything is correct.

#### 5. Apply Configuration

```bash
terraform apply tfplan
```

This will create:
- VPC with public/private/database subnets (Multi-AZ)
- NAT Gateways for private subnet egress
- RDS PostgreSQL database (Multi-AZ)
- S3 buckets (data, assets, logs)
- Application Load Balancer (Multi-AZ)
- CloudFront CDN
- Auto Scaling Group (2-4 instances)
- IAM roles and policies
- CloudWatch dashboards and alarms
- Route53 DNS and health checks

#### 6. Verify Deployment

```bash
# Get outputs
terraform output

# Check ALB health
aws elbv2 describe-target-health --target-group-arn $(terraform output -raw target_group_arn)

# Visit Foundry
open $(terraform output -raw foundry_url)
```

## Configuration Guide

### VPC & Networking

- **VPC CIDR**: 10.0.0.0/16 (customizable)
- **Public Subnets**: Tier-1 (internet-facing ALB)
- **Private Subnets**: Tier-2 (EC2 instances with NAT)
- **Database Subnets**: Tier-3 (RDS isolated)
- **Multi-AZ**: By default, 2 AZs (can increase)

### Database (RDS)

- **Engine**: PostgreSQL 15.3 (configurable)
- **Instance Class**: db.t3.medium (suitable for small-medium campaigns)
- **Storage**: 100 GB gp3 with 3000 IOPS (adjust as needed)
- **Backup**: 30-day retention with automated backups
- **High Availability**: Multi-AZ with automatic failover
- **Monitoring**: Enhanced monitoring, performance insights

**Scaling Considerations**:
- Small campaigns (< 20 players): `db.t3.micro` or `db.t3.small`
- Medium campaigns (20-50 players): `db.t3.medium` (default)
- Large campaigns (50+ players): `db.t3.large` or `db.m5.large`

### Compute (EC2 & ASG)

- **Instance Type**: t3.medium (1 vCPU, 4 GB RAM)
- **AMI**: Ubuntu 22.04 LTS (latest)
- **Auto Scaling**: Min 2, Max 4, Target 2
- **Scaling Trigger**: CPU > 70% (scale up), < 30% (scale down)
- **Health Check**: ELB-based with 300s grace period

**Scaling Considerations**:
- Small deployment: `t3.small` with min/max=1
- Medium deployment: `t3.medium` with min/max=2-3 (default)
- Large deployment: `t3.large` or `m5.large` with min/max=3-5

### Storage (S3)

**Foundry Data Bucket**:
- World data, journals, actors, scenes
- Versioning enabled (30-day rollback)
- Lifecycle: Old versions → Infrequent Access (30d) → Glacier (90d) → Delete (180d)
- Encryption: AES-256 (AWS managed)
- Cost: ~$0.10/GB/month (Standard) → $0.0125/GB/month (Glacier)

**CloudFront Assets Bucket**:
- Module assets, maps, sounds
- Direct upload via Foundry interface
- Distributed globally via CloudFront

**Logs Bucket**:
- ALB and S3 access logs
- Retention: 365 days (auto-delete)

### Load Balancer (ALB)

- **Protocol**: HTTP (80) → HTTPS (301 redirect)
- **HTTPS**: Port 443 with ACM certificate
- **SSL Policy**: ELBSecurityPolicy-TLS-1-2-2017-01 (TLS 1.2+)
- **Target Group**: Port 30000 (Foundry)
- **Health Check**: `/api/health` (30s interval, 2 healthy threshold)
- **Stickiness**: Not required (stateless websocket)

### CDN (CloudFront)

- **Origin 1**: S3 assets bucket (static content)
- **Origin 2**: ALB (Foundry application)
- **Caching**:
  - `/assets/*` → 1 year (versioned assets)
  - `/maps/*` → 1 year (static maps)
  - `/` (root) → No cache (dynamic content)
- **Security Headers**: HSTS, X-Content-Type-Options, X-Frame-Options
- **HTTP/3**: Enabled for faster connections

### DNS (Route53)

- **Record Type**: A (alias) → ALB
- **Health Check**: HTTPS to /api/health
- **Certificate**: Auto-created with ACM (free)
- **Failover**: Route53 evaluates target health

## Security Best Practices

### Network Security

✅ **Implemented**:
- VPC Flow Logs → CloudWatch (30-day retention)
- Security groups with least-privilege rules
- Private subnets for compute with NAT gateway egress
- Database in isolated subnet (no direct internet access)
- VPC Endpoints for S3 and Secrets Manager (no NAT cost)

✅ **Recommendations**:
- Enable GuardDuty for threat detection
- Enable Security Hub for compliance monitoring
- Use AWS WAF on CloudFront for DDoS protection
- Enable VPC endpoint policy for S3 bucket isolation

### Data Security

✅ **Implemented**:
- S3 encryption (AES-256)
- RDS encryption at rest and in transit
- SSL/TLS for ALB
- Deny unencrypted S3 uploads (bucket policy)
- Deny unencrypted transport (HTTPS only)

✅ **Recommendations**:
- Enable MFA for root account
- Use AWS Secrets Manager for sensitive values
- Enable RDS Enhanced Monitoring
- Enable S3 Object Lock for immutable backups

### Access Control

✅ **Implemented**:
- IAM instance profile for EC2 (least-privilege)
- S3 policies restrict to EC2 role only
- Security groups restrict SSH (optional admin_ssh_cidr)
- RDS only accessible from EC2

✅ **Recommendations**:
- Use AWS Systems Manager Session Manager (no SSH keys)
- Enable CloudTrail for audit logging
- Use temporary IAM credentials (STS)
- Implement resource-based access policies

## Monitoring & Logging

### CloudWatch Dashboards

Pre-configured dashboard shows:
- ALB metrics (request count, response times, errors)
- EC2 metrics (CPU, network, disk)
- RDS metrics (connections, latency, storage)
- Application logs (errors, warnings)

**Access**:
```bash
terraform output cloudwatch_dashboard_url
```

### CloudWatch Alarms

Auto-created alarms for:
- **ALB**: Unhealthy hosts, high latency, 4xx/5xx errors
- **EC2**: High CPU, high disk usage, high memory usage
- **RDS**: High CPU, low memory, low disk space, high connections
- **Application**: High error rate

### VPC Flow Logs

Enable network traffic inspection:
```bash
# View flow logs
aws logs tail /aws/vpc/flowlogs/prod --follow
```

### Application Logging

Configure in cloud-init to forward logs to CloudWatch:
- Foundry application logs → `/foundry/{env}/application`
- Docker logs → `/foundry/{env}/docker`
- RDS PostgreSQL logs → `/rds/{env}/postgresql`

## Cost Estimation

**Monthly Cost Breakdown** (t3.medium, 2 instances):

| Component | Monthly Cost | Notes |
|-----------|--------------|-------|
| **EC2** | $30 × 2 = $60 | On-demand, 2 instances |
| **RDS** | $40 | db.t3.medium + storage |
| **ALB** | $18 | Load balancer + hours |
| **CloudFront** | $0 | Assets only, minimal traffic |
| **S3** | $2 | 100GB storage + lifecycle |
| **Data Transfer** | $5-20 | Outbound only |
| **VPC/NAT/Route53** | $10 | VPC, NAT, DNS |
| **CloudWatch** | $2 | Logs + dashboards |
| **Total** | ~$145-175 | Estimates only |

**Cost Optimization**:
- Use Reserved Instances for 30-40% savings
- Use Savings Plans for 20-30% savings
- Archive old backups to S3 Glacier
- Set up Budget Alerts in AWS Billing

## Troubleshooting

### Instances Not Launching

```bash
# Check ASG events
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name $(terraform output -raw asg_name) \
  --max-records 10

# Check CloudWatch logs
aws logs tail /foundry/prod/docker --follow
```

### Database Connection Issues

```bash
# Check security group
aws ec2 describe-security-groups \
  --group-ids $(terraform output -raw rds_sg_id)

# Test connection from EC2
aws ssm start-session --target i-xxxxxxxxx
# Inside EC2:
psql -h <rds-endpoint> -U foundryadmin -d foundry
```

### ALB Not Routing Traffic

```bash
# Check target health
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw target_group_arn)

# Check security group (EC2 must allow ALB)
aws ec2 describe-security-groups --group-ids sg-xxxxxxxxx
```

### CloudFront Cache Issues

```bash
# Invalidate cache
aws cloudfront create-invalidation \
  --distribution-id $(terraform output -raw cf_distribution_id) \
  --paths "/*"
```

## Maintenance & Operations

### Scaling Instances

```bash
# Update ASG configuration
terraform apply -var="asg_desired_capacity=3"
```

### Database Upgrades

```bash
# Minor version upgrade (automatic patches during maintenance window)
terraform apply -var="postgres_version=15.4"

# Major version upgrade (requires downtime, manual process)
# See: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_UpgradeDBInstance.PostgreSQL.html
```

### Backup & Restore

```bash
# Create manual snapshot
aws rds create-db-snapshot \
  --db-instance-identifier prod-foundry-db \
  --db-snapshot-identifier prod-foundry-db-manual-backup-$(date +%Y%m%d)

# List snapshots
aws rds describe-db-snapshots --query 'DBSnapshots[*].[DBSnapshotIdentifier,SnapshotCreateTime]'

# Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier prod-foundry-db-restored \
  --db-snapshot-identifier prod-foundry-db-manual-backup-20240101
```

### Monitoring S3 Growth

```bash
# List bucket sizes
aws s3 ls s3://prod-foundry-data-123456789/ --recursive --summarize
```

## Disaster Recovery

### RTO & RPO

- **Failover Time**: <2 minutes (ALB + RDS Multi-AZ)
- **Backup Window**: Every 6 hours (adjust via `backup_retention_days`)
- **Restore Time**: <5 minutes from snapshot

### Backup Strategy

1. **Automated**: RDS backups every 6 hours, 30-day retention
2. **Manual**: Create snapshots before major changes
3. **Verification**: Test restore monthly

### Disaster Recovery Steps

If primary AZ fails:
1. ALB automatically routes to healthy AZ-2 instance
2. RDS failover to standby (automatic, ~1 minute)
3. No manual intervention required

If complete account failure:
1. Restore RDS from snapshot to new region
2. Rebuild ASG with new security group
3. Update Route53 to new ALB

## Cleanup & Destruction

```bash
# Plan destruction
terraform plan -destroy

# Destroy infrastructure
terraform destroy

# Note: RDS final snapshot will be created before deletion
```

## Additional Resources

- [Foundry VTT Docker Documentation](https://github.com/felddy/foundryvtt-docker)
- [AWS RDS PostgreSQL Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.html)
- [AWS ALB Documentation](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## Support & Issues

For infrastructure issues:
1. Check CloudWatch logs: `terraform output cloudwatch_dashboard_url`
2. Review VPC Flow Logs: `aws logs tail /aws/vpc/flowlogs/{environment}`
3. Check Terraform state: `terraform state list`
4. Review AWS Console for service health

## License

This infrastructure code is provided as-is for Foundry VTT deployment.
