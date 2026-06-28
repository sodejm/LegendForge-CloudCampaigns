# AWS Foundry VTT - Quick Reference

## Deploy in 4 Steps

```bash
cd deployments/aws
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform plan && terraform apply
```

## Essential Commands

### Configuration
```bash
cp terraform.tfvars.example terraform.tfvars   # Create config
vim terraform.tfvars                           # Edit values
```

### Deployment
```bash
terraform init                                 # Initialize
terraform plan -out=tfplan                    # Validate
terraform apply tfplan                        # Deploy
terraform destroy                             # Remove
```

### Verify
```bash
terraform output                              # Show outputs
terraform output foundry_url                  # Get Foundry URL
terraform output cloudwatch_dashboard_url     # Get monitoring URL
```

### Monitoring
```bash
aws logs tail /foundry/prod/application --follow     # View app logs
aws logs tail /foundry/prod/docker --follow          # View container logs
aws elbv2 describe-target-health --target-group-arn <ARN>  # Check health
aws autoscaling describe-scaling-activities --auto-scaling-group-name <ASG_NAME>
```

### Scale
```bash
terraform apply -var="asg_desired_capacity=3"  # Scale to 3 instances
terraform apply -var="ec2_instance_type=t3.large"  # Larger instances
terraform apply -var="rds_instance_class=db.t3.large"  # Larger DB
```

### Database
```bash
# Connect from EC2
aws ssm start-session --target i-xxxxxxxxx
psql -h <rds-endpoint> -U foundryadmin -d foundry

# Backup
aws rds create-db-snapshot --db-instance-identifier prod-foundry-db

# View backups
aws rds describe-db-snapshots
```

### S3
```bash
# Check data usage
aws s3 ls s3://prod-foundry-data-123456789/ --recursive --summarize

# View versioning
aws s3api list-object-versions --bucket prod-foundry-data-123456789
```

### CloudFront
```bash
# Invalidate cache
aws cloudfront create-invalidation \
  --distribution-id <ID> --paths "/*"

# Get domain
terraform output cloudfront_domain
```

### Troubleshooting
```bash
# Check ASG events
aws autoscaling describe-scaling-activities --auto-scaling-group-name prod-foundry-asg

# View system logs
aws ec2 get-console-output --instance-id i-xxxxxxxxx

# Check security groups
aws ec2 describe-security-groups --filters Name=tag:Name,Values=prod-*

# View VPC endpoints
aws ec2 describe-vpc-endpoints
```

## Key Files & Locations

| File | Purpose |
|------|---------|
| `terraform.tfvars` | Configuration (NEVER commit) |
| `main.tf` | Deployment orchestration |
| `variables.tf` | Input variables |
| `../modules/aws-*` | Reusable modules |
| `README.md` | Comprehensive guide |
| `DEPLOYMENT_GUIDE.md` | Step-by-step instructions |
| `ARCHITECTURE.md` | Technical diagrams |
| `SECRETS_MANAGEMENT.md` | Security guide |

## Essential Variables

```hcl
# Network
aws_region = "us-east-1"
vpc_cidr = "10.0.0.0/16"

# Compute
ec2_instance_type = "t3.medium"
asg_desired_capacity = 2

# Database
database_username = "foundryadmin"
database_password = "SECURE_PASSWORD"
rds_instance_class = "db.t3.medium"

# Foundry
foundry_hostname = "vtt.example.com"
foundry_license_key = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
route53_zone_id = "Z1234567890ABC"
```

## Security Best Practices

✅ DO:
- Store secrets in AWS Secrets Manager
- Use IAM roles, not access keys
- Enable MFA on root account
- Review CloudTrail logs monthly
- Rotate passwords every 30 days
- Use VPC endpoints (no NAT)
- Enable encryption everywhere
- Set up monitoring & alarms

❌ DON'T:
- Commit secrets to git
- Use root AWS credentials
- Store passwords in code
- Share access keys
- Leave backups unencrypted
- Disable security groups
- Skip monitoring setup
- Ignore CloudTrail logs

## Costs at a Glance

| Component | Cost/Month |
|-----------|-----------|
| EC2 (2×t3.medium) | $60 |
| RDS (db.t3.medium) | $40 |
| ALB | $18 |
| S3 + Data Transfer | $20 |
| VPC + NAT | $32 |
| Monitoring | $10 |
| **TOTAL** | **~$180** |

**Options to reduce costs:**
- Use Reserved Instances (save 30-40%)
- Scale down (t3.small, db.t3.micro)
- Archive to Glacier (save 90%)
- Single AZ (not recommended for prod)

## Monitoring URLs

Once deployed:
```bash
Foundry:          https://vtt.example.com
CloudWatch:       terraform output cloudwatch_dashboard_url
CloudFront:       terraform output cloudfront_domain
RDS Metrics:      AWS Console > RDS > prod-foundry-db
ALB Health:       AWS Console > EC2 > Target Groups
```

## Common Issues & Fixes

### Instances not starting
```bash
aws autoscaling describe-scaling-activities --auto-scaling-group-name prod-foundry-asg
aws ec2 get-console-output --instance-id i-xxxxxxxxx
```

### Database connection failed
```bash
# Check security group allows EC2 → RDS
aws ec2 describe-security-groups --group-ids sg-xxxxxxxxx

# Test from EC2
aws ssm start-session --target i-xxxxxxxxx
psql -h <endpoint> -U foundryadmin
```

### DNS not resolving
```bash
# Check Route53 record
aws route53 list-resource-record-sets --hosted-zone-id Z1234567890ABC

# Force refresh
nslookup vtt.example.com 8.8.8.8
```

### CloudFront caching issues
```bash
# Clear cache
aws cloudfront create-invalidation --distribution-id <ID> --paths "/*"
```

## Environment Variables

```bash
export AWS_REGION="us-east-1"
export AWS_PROFILE="default"

# Or use directly with terraform
export TF_VAR_database_password="secure_password"
export TF_VAR_foundry_license_key="XXXXX-XXXXX-..."
```

## Backup Strategy

### Automated
- RDS: Every 6 hours, 30-day retention
- S3: Versioning enabled, 180-day retention

### Manual
```bash
# Create snapshot
aws rds create-db-snapshot --db-instance-identifier prod-foundry-db \
  --db-snapshot-identifier backup-$(date +%Y%m%d)

# Verify
aws rds describe-db-snapshots --query 'DBSnapshots[*].[DBSnapshotIdentifier,SnapshotCreateTime]'
```

## Disaster Recovery

**If primary instance fails:**
1. ALB automatically routes to healthy instance
2. Check target health: `aws elbv2 describe-target-health --target-group-arn <ARN>`

**If database fails:**
1. RDS automatic failover (< 1 minute)
2. Check: `aws rds describe-db-instances --db-instance-identifier prod-foundry-db`

**If complete failure:**
1. Restore from snapshot
2. Create new ASG
3. Update Route53
4. Estimated recovery: 15-30 minutes

## State Management

### Local State (development)
```bash
# State file: terraform.tfstate (git-ignored)
terraform init  # Creates local state
```

### Remote State (production - recommended)
```bash
# Update main.tf with S3 backend
terraform init  # Migrates to remote state
terraform state list  # View remote state
terraform state show aws_instance.example  # Inspect resource
```

## Maintenance Schedule

| Frequency | Task |
|-----------|------|
| Daily | Monitor CloudWatch dashboard |
| Weekly | Review error logs |
| Monthly | Test disaster recovery |
| Quarterly | Update security |
| Yearly | Major version upgrades |

## Support Resources

- **Terraform**: https://registry.terraform.io/providers/hashicorp/aws
- **AWS**: https://docs.aws.amazon.com
- **Foundry**: https://forums.foundrynet.com
- **GitHub**: https://github.com/terraform-aws-modules/

---

**Quick Help:**
```bash
terraform output                    # Show all outputs
terraform state list               # Show resources
terraform fmt                      # Format code
terraform validate                 # Validate syntax
terraform import aws_instance.id   # Import existing resources
```

**Get Help:**
- Check: `deployments/aws/README.md`
- Read: `DEPLOYMENT_GUIDE.md`
- Review: `ARCHITECTURE.md`
