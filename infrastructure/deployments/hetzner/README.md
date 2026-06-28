# Hetzner Foundry VTT Deployment

Cost-effective Terraform deployment of LegendForge on Hetzner Cloud with high reliability and simple management.

## 📋 Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│              Cloudflare (DNS & Tunnel)              │
│                                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │      Hetzner Cloud (eu-central)               │  │
│  │                                               │  │
│  │  ┌─────────────────────────────────────────┐  │  │
│  │  │    VPC Network (10.0.0.0/24)            │  │  │
│  │  │                                         │  │  │
│  │  │  ┌──────────────────────────────────┐   │  │  │
│  │  │  │  Hetzner Server (cx21)           │   │  │  │
│  │  │  │                                  │   │  │  │
│  │  │  │  • Ubuntu 22.04 LTS              │   │  │  │
│  │  │  │  • Docker + Foundry              │   │  │  │
│  │  │  │  • Cloudflare Tunnel (outbound)  │   │  │  │
│  │  │  │                                  │   │  │  │
│  │  │  │  ┌──────────────────────────┐    │   │  │  │
│  │  │  │  │ Volume (20GB, SSD)       │    │   │  │  │
│  │  │  │  │ Foundry Data             │    │   │  │  │
│  │  │  │  └──────────────────────────┘    │   │  │  │
│  │  │  │                                  │   │  │  │
│  │  │  └──────────────────────────────────┘   │  │  │
│  │  │                                         │  │  │
│  │  │  Firewall: SSH optional, outbound open │  │  │
│  │  └─────────────────────────────────────────┘  │  │
│  │                                               │  │
│  └───────────────────────────────────────────────┘  │
│                                                     │
└─────────────────────────────────────────────────────┘
```

## 💡 Why Hetzner?

- **Cost-Effective**: ~$5-10/month for cx21 server + volume
- **Simplicity**: Straightforward API, clear pricing
- **Performance**: SSD storage, fast networking
- **Reliability**: 99.9% uptime SLA
- **Data Residency**: EU-based (GDPR compliant)

## 🚀 Prerequisites

- Hetzner Cloud account with API token
- Terraform >= 1.0
- hcloud provider ~> 1.40

## 🎯 Quick Deployment

### Step 1: Set Environment

```bash
export HCLOUD_TOKEN="your-hetzner-api-token"
```

### Step 2: Configure Variables

```bash
cp config/foundry.auto.tfvars.example config/foundry.auto.tfvars
# Edit with your Foundry hostname and settings
```

### Step 3: Deploy

```bash
cd deployments/hetzner
terraform init
terraform plan -var-file="../../config/foundry.auto.tfvars"
terraform apply -var-file="../../config/foundry.auto.tfvars"
```

### Step 4: Access

```bash
# Get server IP
SERVER_IP=$(terraform output -raw server_public_ipv4)

# Connect
ssh root@$SERVER_IP

# Monitor Foundry
docker logs -f foundry

# Access at https://your-foundry-hostname.com
```

## 💰 Cost Breakdown

**Monthly:**
- Server (cx21): €5.00
- Volume (20GB): €1.00
- Traffic (included up to 21TB): ~€0

**Total: €6.00/month (~$6.50 USD)**

## 📖 Operations

### Backup
Volume backups are created manually:
```bash
hcloud volume create-backup $VOLUME_ID
```

### Resize
Increase volume size by updating variable and applying.

### Spin Down
```bash
terraform apply -var="compute_enabled=false" \
  -var-file="../../config/foundry.auto.tfvars"
```

### Destroy
```bash
terraform destroy \
  -var-file="../../config/foundry.auto.tfvars"
```

## 🔗 Resources

- [Hetzner Cloud Docs](https://docs.hetzner.cloud)
- [hcloud Provider Docs](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs)
- [Foundry VTT Docker](https://github.com/felddy/foundryvtt-docker)

## 📄 License

This configuration is provided as-is. See LICENSE for details.
