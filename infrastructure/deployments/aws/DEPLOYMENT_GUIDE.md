# AWS Foundry VTT Deployment Guide

Complete step-by-step guide for deploying Foundry VTT on AWS.

## Prerequisites Checklist

- [ ] AWS Account with appropriate IAM permissions
- [ ] Terraform 1.0+ installed locally
- [ ] AWS CLI v2 configured with credentials
- [ ] Route53 hosted zone for your domain
- [ ] Foundry VTT license key
- [ ] Cloudflare account (optional, for tunneling)
- [ ] SSL/TLS certificate (ACM will auto-create)

## Step 1: Prepare AWS Account

### Create S3 Bucket for Terraform State

```bash
# Set variables
BUCKET_NAME="my-foundry-terraform-state"
AWS_REGION="us-east-1"

# Create bucket
aws s3 mb "s3://${BUCKET_NAME}" --region "${AWS_REGION}"

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket "${BUCKET_NAME}" \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket "${BUCKET_NAME}" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Block public access
aws s3api put-public-access-block \
  --bucket "${BUCKET_NAME}" \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

### Create DynamoDB Lock Table

```bash
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region "${AWS_REGION}"
```

## Step 2: Configure Terraform

### Create terraform.tfvars

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit with your values:

```hcl
aws_region = "us-east-1"
environment = "prod"
vpc_cidr = "10.0.0.0/16"

# Database
database_username = "foundryadmin"
database_password = "YOUR_SECURE_PASSWORD_32_CHARS"

# EC2
asg_desired_capacity = 2

# Foundry
foundry_hostname = "vtt.example.com"
foundry_image = "felddy/foundryvtt@sha256:DIGEST_HERE"
cloudflare_tunnel_token = "YOUR_TOKEN"
foundry_license_key = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
foundry_admin_key = "YOUR_ADMIN_PASSWORD"

# DNS
route53_zone_id = "Z1234567890ABC"
```

### Enable Remote State (Production)

Uncomment in main.tf:

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

## Step 3: Deploy Infrastructure

### Initialize Terraform

```bash
cd deployments/aws
terraform init
```

### Plan Deployment

```bash
terraform plan -out=tfplan
```

Review output for any errors or unexpected changes.

### Apply Configuration

```bash
terraform apply tfplan
```

Wait for deployment to complete (typically 10-15 minutes).

## Step 4: Verify Deployment

### Check Outputs

```bash
terraform output
```

Key outputs:
- `foundry_url`: URL to access Foundry
- `alb_dns_name`: Load balancer DNS
- `rds_endpoint`: Database endpoint
- `cloudwatch_dashboard_url`: Monitoring dashboard

### Test Health Checks

```bash
# Get target group ARN
TG_ARN=$(terraform output -raw target_group_arn)

# Check target health
aws elbv2 describe-target-health --target-group-arn "$TG_ARN"

# Expected: "State": "healthy"
```

### Access Foundry

```bash
# Get Foundry URL
FOUNDRY_URL=$(terraform output -raw foundry_url)
echo "Visit: $FOUNDRY_URL"
```

Wait for DNS propagation (5-10 minutes). Access the admin password from terraform.tfvars.

## Step 5: Initial Configuration

### Access Admin Panel

1. Navigate to `https://vtt.example.com/setup`
2. Enter admin key from terraform.tfvars
3. Configure game system and modules
4. Create world

### Verify Database Connection

Foundry should automatically use the RDS database configured in cloud-init.

### Test S3 Integration

1. Upload a map or module
2. Verify files appear in S3 bucket:
   ```bash
   aws s3 ls s3://prod-foundry-data-123456789/ --recursive
   ```

### Configure CloudFront Cache

Assets are automatically served through CloudFront. Verify:

```bash
# Get CloudFront domain
CF_DOMAIN=$(terraform output -raw cloudfront_domain)
echo "CloudFront: https://$CF_DOMAIN"
```

## Step 6: Monitoring Setup

### Access CloudWatch Dashboard

```bash
terraform output cloudwatch_dashboard_url
```

Pre-configured dashboards show:
- ALB metrics
- EC2 metrics
- RDS metrics
- Application logs

### Configure Alarms

Alarms are auto-created for:
- High CPU (EC2, RDS)
- Unhealthy targets
- Database connection count
- Disk usage

Customize as needed:
```bash
aws cloudwatch describe-alarms --alarm-name-prefix prod-foundry
```

## Step 7: Backup Configuration

### Verify RDS Backups

```bash
# Check backup configuration
aws rds describe-db-instances \
  --db-instance-identifier prod-foundry-db \
  --query 'DBInstances[0].{BackupRetention:BackupRetentionPeriod,BackupWindow:PreferredBackupWindow}'
```

### Create Manual Backup

```bash
aws rds create-db-snapshot \
  --db-instance-identifier prod-foundry-db \
  --db-snapshot-identifier prod-foundry-db-backup-$(date +%Y%m%d)
```

### S3 Versioning

Versioning is enabled automatically. Verify:

```bash
aws s3api get-bucket-versioning \
  --bucket prod-foundry-data-123456789
```

## Step 8: Security Hardening

### Enable AWS GuardDuty (Threat Detection)

```bash
aws guardduty create-detector --enable
```

### Enable Security Hub

```bash
aws securityhub enable-security-hub
```

### Review IAM Permissions

Verify EC2 role has minimal permissions:

```bash
aws iam get-role-policy \
  --role-name prod-foundry-ec2-role \
  --policy-name prod-foundry-s3-policy
```

### Enable MFA on Root Account

In AWS Console:
1. Go to Account Settings
2. Enable MFA
3. Store recovery codes securely

### Rotate Secrets Regularly

Database password: Every 30 days
Foundry keys: As needed
Cloudflare tokens: Every 90 days

## Step 9: Load Testing

### Generate Test Load

```bash
# Using Apache Bench
ab -n 1000 -c 10 https://vtt.example.com/

# Monitor in CloudWatch
terraform output cloudwatch_dashboard_url
```

### Scale Up if Needed

Increase desired capacity:

```bash
terraform apply -var="asg_desired_capacity=3"
```

Monitor CPU and connection metrics.

## Step 10: Documentation & Handoff

### Document Access

Create a document with:
- Foundry URL
- Admin panel access
- Database connection string (for backups)
- CloudWatch dashboard link
- Emergency contacts

### Team Training

Ensure team knows:
- How to access Foundry
- How to monitor via CloudWatch
- How to request scaling changes
- Where to find documentation

### Runbooks

Create runbooks for:
- Scaling instances
- Restoring from backup
- Updating Foundry version
- Security incident response

## Troubleshooting

### Instances Not Starting

Check Auto Scaling Group events:

```bash
ASG_NAME=$(terraform output -raw asg_name)
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name "$ASG_NAME" \
  --max-records 5
```

Check EC2 instance logs:

```bash
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=prod-foundry-instance" \
  --query 'Reservations[0].Instances[0].[InstanceId,State.Name]'

# Get system log
aws ec2 get-console-output --instance-id i-xxxxxxxxx
```

### Database Connection Failed

Verify security group:

```bash
aws ec2 describe-security-groups \
  --group-names prod-rds-sg \
  --query 'SecurityGroups[0].IpPermissions'
```

Test connection from EC2:

```bash
# SSH to EC2 (requires admin_ssh_cidr set)
aws ssm start-session --target i-xxxxxxxxx

# Inside EC2, test database
psql -h <rds-endpoint> -U foundryadmin -d foundry
```

### CloudFront Cache Issues

Invalidate cache:

```bash
CF_ID=$(terraform output -raw cloudfront_distribution_id)
aws cloudfront create-invalidation \
  --distribution-id "$CF_ID" \
  --paths "/*"
```

### DNS Not Resolving

Verify Route53 record:

```bash
ZONE_ID=$(terraform output -raw route53_zone_id)
aws route53 list-resource-record-sets \
  --hosted-zone-id "$ZONE_ID" \
  --query 'ResourceRecordSets[?Name==`vtt.example.com.`]'
```

Force DNS refresh:

```bash
nslookup vtt.example.com 8.8.8.8
```

## Post-Deployment Tasks

- [ ] Configure Foundry modules and systems
- [ ] Create first world
- [ ] Test websocket connections
- [ ] Invite players for testing
- [ ] Monitor for 24 hours
- [ ] Adjust auto-scaling thresholds
- [ ] Document custom configurations
- [ ] Schedule regular backups
- [ ] Setup team notification channels

## Maintenance Schedule

- Daily: Monitor CloudWatch dashboard
- Weekly: Review logs for errors
- Monthly: Test disaster recovery
- Quarterly: Review security settings
- Yearly: Update documentation

## Support Resources

- Foundry Forums: https://forums.foundrynet.com
- AWS Documentation: https://docs.aws.amazon.com
- Terraform Docs: https://registry.terraform.io/providers/hashicorp/aws
- GitHub Issues: https://github.com/foundryvtt-docker
