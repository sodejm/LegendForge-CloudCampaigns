# Secrets Management for AWS Foundry Deployment

This guide covers best practices for managing sensitive data in production.

## Overview

Secrets required for Foundry deployment:

| Secret | Sensitivity | Storage | Rotation |
|--------|-------------|---------|----------|
| Database Password | High | Secrets Manager | 30-90 days |
| Foundry License Key | High | Secrets Manager | Never |
| Foundry Admin Key | High | Secrets Manager | 30 days |
| Cloudflare Tunnel Token | High | Secrets Manager | 90 days |
| AWS Access Keys | Critical | IAM | Never (use STS) |
| API Keys | Medium | Secrets Manager | 90 days |

## Method 1: AWS Secrets Manager (Recommended)

### Setup

Store secrets in AWS Secrets Manager:

```bash
# Create database password secret
aws secretsmanager create-secret \
  --name prod/foundry/database/password \
  --secret-string "YOUR_SECURE_PASSWORD" \
  --tags Key=Environment,Value=prod Key=Application,Value=foundry

# Create Foundry license key
aws secretsmanager create-secret \
  --name prod/foundry/license-key \
  --secret-string "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX-XXXXX" \
  --tags Key=Environment,Value=prod

# Create Cloudflare tunnel token
aws secretsmanager create-secret \
  --name prod/foundry/cloudflare-token \
  --secret-string "YOUR_TUNNEL_TOKEN" \
  --tags Key=Environment,Value=prod
```

### Terraform Integration

Retrieve secrets from Secrets Manager in Terraform:

```hcl
# Get secret value
data "aws_secretsmanager_secret" "db_password" {
  name = "prod/foundry/database/password"
}

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = data.aws_secretsmanager_secret.db_password.id
}

# Use in RDS module
module "rds" {
  source = "../../modules/aws-rds"

  database_password = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string).password
  # ... other variables
}
```

### Automatic Rotation

Configure automatic secret rotation:

```bash
# Enable rotation for database password (every 30 days)
aws secretsmanager rotate-secret \
  --secret-id prod/foundry/database/password \
  --rotation-rules AutomaticallyAfterDays=30 \
  --rotation-lambda-arn arn:aws:lambda:region:account:function:SecretsManagerRotation
```

### EC2 Instance Access

EC2 instances retrieve secrets via VPC Endpoint (no internet required):

```bash
# Inside EC2 instance
aws secretsmanager get-secret-value \
  --secret-id prod/foundry/license-key \
  --query SecretString \
  --output text
```

## Method 2: GitHub Secrets (CI/CD)

For GitHub Actions deployment:

```yaml
# .github/workflows/deploy.yaml
name: Deploy to AWS

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment (prod/staging)'
        required: true
        default: 'staging'

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment }}

    steps:
      - uses: actions/checkout@v3

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Terraform Deploy
        run: |
          cd deployments/aws
          terraform init
          terraform apply -auto-approve \
            -var="database_password=${{ secrets.DB_PASSWORD }}" \
            -var="foundry_license_key=${{ secrets.FOUNDRY_LICENSE_KEY }}" \
            -var="foundry_admin_key=${{ secrets.FOUNDRY_ADMIN_KEY }}" \
            -var="cloudflare_tunnel_token=${{ secrets.CF_TUNNEL_TOKEN }}"
```

## Method 3: Local .tfvars (Development Only)

For local development, use a git-ignored `.tfvars` file:

```bash
# Create file (never commit)
cat > deployments/aws/secrets.tfvars << EOF
database_password       = "dev_password_change_me"
foundry_license_key     = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
foundry_admin_key       = "dev_admin_password"
cloudflare_tunnel_token = "eyJhbGci..."
