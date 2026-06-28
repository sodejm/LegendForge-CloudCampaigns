# LegendForge on Azure - Quick Start Guide

## 5-Minute Setup

### Step 1: Prerequisites (1 min)

```bash
# Install Azure CLI and Terraform
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip && sudo mv terraform /usr/local/bin/

# Verify
az --version
terraform --version
```

### Step 2: Azure Login (1 min)

```bash
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### Step 3: Generate SSH Key (1 min)

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/azure_foundry
cat ~/.ssh/azure_foundry.pub  # Copy this
```

### Step 4: Prepare Variables (1 min)

```bash
cd deployments/azure
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
- Set `foundry_license_key`
- Paste `vm_ssh_public_key`
- Set `database_password`
- Set `alert_email`

### Step 5: Deploy (1 min)

```bash
terraform init
terraform plan
terraform apply
```

## Access Foundry

After deployment completes (~20 minutes):

```bash
# Get public IP
terraform output load_balancer_public_ip

# Access Foundry
open http://<PUBLIC_IP>
```

## What Got Created?

✅ Virtual Network with 4 subnets and DDoS protection
✅ 2-10 auto-scaling VMs running Foundry
✅ MySQL/PostgreSQL database with automatic backups
✅ Blob storage with CDN for media
✅ Key Vault for secrets
✅ Log Analytics & Application Insights
✅ Auto-scaling based on CPU/memory
✅ Load balancer with health checks
✅ Alert rules for high CPU, low memory, storage quota

## Costs

**Estimated Monthly Cost (Production):**
- VMs (2x D4s): ~$380
- Database (Standard_B2s): ~$100
- Storage (100GB GZRS): ~$10
- CDN: ~$20
- Monitoring: ~$10
- **Total**: ~$520/month

**Save Money:**
```bash
# Use Standard_B2s VMs for non-peak
vm_size = "Standard_B2s"

# Reduce backup retention
backup_retention_days = 14
```

## Common Tasks

### Scale Manually

```bash
# Scale to 5 instances
terraform apply -var="scale_set_capacity=5"
```

### Check Logs

```bash
# Recent Foundry logs
az vmss run-command invoke \
  --resource-group rg-legendforge-prod \
  --name vmss-legendforge-prod \
  --command-id RunShellScript \
  --scripts "docker logs foundry | tail -50"
```

### Database Access

```bash
# Connect to MySQL
mysql -h mysql-legendforge-prod.mysql.database.azure.com \
  -u azureadmin -p
```

### Monitoring

Visit Azure Portal → Search "dashboard-legendforge-prod"

## Troubleshooting

**Infrastructure not scaling?**
```bash
az vmss show --name vmss-legendforge-prod --resource-group rg-legendforge-prod
```

**Can't access Foundry?**
```bash
# Check load balancer
az lb show --name lb-legendforge-prod --resource-group rg-legendforge-prod

# Check VMs are healthy
az vmss list-instances --resource-group rg-legendforge-prod --vmss-name vmss-legendforge-prod
```

**Database connection issues?**
```bash
# Check firewall
az mysql flexible-server firewall-rule list \
  --resource-group rg-legendforge-prod \
  --server-name mysql-legendforge-prod
```

## Delete Everything

```bash
terraform destroy
```

## Next Steps

- See `AZURE_DEPLOYMENT.md` for detailed guide
- Configure custom domain with Application Gateway
- Setup SSL/TLS certificates
- Configure backups and disaster recovery

## Support

- Terraform: https://www.terraform.io/docs
- Azure: https://docs.microsoft.com/azure/
- Foundry: https://foundryvtt.com/article/installation/
