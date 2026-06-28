# LegendForge Multi-Cloud Infrastructure for Foundry VTT

![LegendForge Logo](resources/LegendForge_Logo.png)

LegendForge is a universal, production-ready **Terraform infrastructure platform** for deploying Foundry VTT across multiple cloud providers with security-first defaults, automatic backups, and support for many tabletop game systems.

## 📋 Overview

LegendForge provides modular infrastructure for teams and game masters who want to run **Foundry VTT as system-agnostic tabletop infrastructure** instead of a single-ruleset deployment.

Deploy LegendForge on:

| Platform    | Cost/Month | Best For                | Status      |
| ----------- | ---------- | ----------------------- | ----------- |
| **AWS**     | $65-75     | Enterprise, scalability | ✅ Complete |
| **Azure**   | $50-60     | Enterprise, RBAC        | ✅ Complete |
| **GCP**     | $48-50     | Simplicity, monitoring  | ✅ Complete |
| **Hetzner** | €6-8       | Cost-conscious, EU      | ✅ Complete |

LegendForge is designed to support **any Foundry-compatible tabletop system** by keeping infrastructure, storage, networking, backups, and operational workflows independent from the specific ruleset running inside Foundry.

## 🎲 Multi-System Support

LegendForge is built for campaigns and communities running multiple systems side by side, including:

- **Dungeons & Dragons 5e**
- **Pathfinder 1e and Pathfinder 2e**
- **World of Darkness** titles such as Vampire, Werewolf, Hunter, and related Storyteller games
- **Fate** variants including Core, Accelerated, and Condensed
- **Powered by the Apocalypse** games
- **Forbidden Lands**
- **GUMSHOE**-based games
- Additional Foundry-compatible systems, worlds, and modules

📚 See **[SUPPORTED_SYSTEMS.md](SUPPORTED_SYSTEMS.md)** for the full compatibility overview.

## 🧭 Project Philosophy

LegendForge treats Foundry as **universal tabletop infrastructure**:

- Infrastructure should be **agnostic to rulesets and genres**
- Security, backups, and observability should work the same way for every campaign
- Cloud architecture should be **portable across providers**
- Documentation should help operators run one world or many worlds with confidence
- The platform should scale from a home game to a multi-campaign community

📖 See **[PROJECT_PHILOSOPHY.md](PROJECT_PHILOSOPHY.md)** for the full philosophy statement.

## 🎯 Key Features

- ✅ **LegendForge Branding**: Repositioned as universal tabletop infrastructure
- ✅ **Multi-System Ready**: Works with Foundry deployments for many RPG systems
- ✅ **Tunnel-First Security**: Cloudflare Tunnel for ingress (no exposed ports)
- ✅ **IaC Everything**: Fully declarative, version-controlled infrastructure
- ✅ **Multi-Cloud**: Deploy to any platform with the same operational model
- ✅ **High Availability**: Automated backups, monitoring, alerting
- ✅ **Secrets Management**: Cloud-native secret storage (Vault, Key Vault, Secret Manager)
- ✅ **Cost Optimized**: Right-sized instances, easy spin-down
- ✅ **Comprehensive Documentation**: Step-by-step guides for each platform and operating model

## 📁 Repository Structure

```text
LegendForge-CloudCampaigns/
├── modules/
│   ├── foundry-app/            # Provider-agnostic Foundry setup module
│   │   ├── variables.tf        # Foundry configuration inputs
│   │   └── templates/          # Cloud-init templates
│   │
│   ├── aws/                    # AWS module (EC2, VPC, EBS, IAM, CloudWatch)
│   ├── azure/                  # Azure module (VMs, VNets, Key Vault, NSGs)
│   ├── gcp/                    # GCP module (Compute Engine, VPC, Secret Manager)
│   ├── providers/
│   │   └── hetzner/            # Hetzner module (Servers, Networks, Volumes)
│   └── [Other modules]
│
├── infrastructure/deployments/
│   ├── aws/                    # AWS deployment configuration
│   ├── azure/                  # Azure deployment configuration
│   ├── gcp/                    # GCP deployment configuration
│   └── hetzner/                # Hetzner deployment configuration
│
├── config/
│   ├── foundry.auto.tfvars.example   # Foundry + LegendForge settings template
│   ├── secrets.auto.tfvars.example   # Secrets template (KEEP PRIVATE!)
│   └── [auto.tfvars files - git-ignored]
│
├── SUPPORTED_SYSTEMS.md        # Foundry system compatibility guidance
├── PROJECT_PHILOSOPHY.md       # Universal tabletop infrastructure philosophy
├── ATTRIBUTION.md              # Upstream projects and license references
├── CREDITS.md                  # Community acknowledgments
├── DOCUMENTATION_INDEX.md      # Documentation map
└── README.md                   # This file
```

## 🚀 Quick Start

### Prerequisites

1. **Terraform** (>= 1.0)

   ```bash
   # macOS
   brew install terraform

   # Linux
   curl https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
   echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
   sudo apt-get update && sudo apt-get install terraform
   ```

2. **Cloud Provider CLI**
   - AWS: `aws-cli`
   - Azure: `az` CLI
   - GCP: `gcloud` CLI
   - Hetzner: None required (uses API token)

3. **Foundry VTT Prerequisites**
   - Valid Foundry VTT license key
   - Foundry admin password (generate a strong random value)
   - Cloudflare account with DNS zone
   - Cloudflare Tunnel created and token generated
   - A target Foundry system or world you plan to install after deployment

### Configuration

1. **Copy configuration templates:**

   ```bash
   cp config/foundry.auto.tfvars.example config/foundry.auto.tfvars
   cp config/secrets.auto.tfvars.example config/secrets.auto.tfvars
   ```

2. **Edit `config/foundry.auto.tfvars`:**

   ```hcl
   foundry_hostname = "vtt.yourdomain.com"
   cloudflare_zone = "yourdomain.com"
   data_volume_size_gb = 20
   compute_enabled = true
   ```

3. **Edit `config/secrets.auto.tfvars`** (⚠️ Keep private!):
   ```hcl
   cloudflare_account_id = "your-account-id"
   cloudflare_api_token = "your-token"
   foundry_license_key = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
   foundry_admin_key = "very-long-secure-random-password"
   cloudflare_tunnel_token = "your-tunnel-token"
   ```

## 🗺️ Choosing a Game System

LegendForge does not hard-code a single ruleset into the infrastructure. After Foundry is online, install the system and content you need inside Foundry itself.

Recommended operator workflow:

1. Deploy LegendForge infrastructure on your preferred cloud.
2. Confirm the Foundry instance is healthy and reachable through Cloudflare Tunnel.
3. Install your desired Foundry game system.
4. Restore or create worlds for one or more campaigns.
5. Add system-specific modules only after validating core platform stability.

For guidance on common system families, see **[SUPPORTED_SYSTEMS.md](SUPPORTED_SYSTEMS.md)**.

## 🎯 Platform Deployment Guides

### AWS Deployment

```bash
cd infrastructure/deployments/aws
terraform init
terraform plan -var-file="../../config/foundry.auto.tfvars" -var-file="../../config/secrets.auto.tfvars"
terraform apply -var-file="../../config/foundry.auto.tfvars" -var-file="../../config/secrets.auto.tfvars"
```

**Features:** VPC, EC2, EBS, RDS-ready, CloudWatch monitoring, Systems Manager Session Manager

→ [AWS Deployment Guide](infrastructure/deployments/aws/README.md)

### Azure Deployment

```bash
cd infrastructure/deployments/azure
terraform init
terraform plan -var-file="../../config/foundry.auto.tfvars" -var-file="../../config/secrets.auto.tfvars"
terraform apply -var-file="../../config/foundry.auto.tfvars" -var-file="../../config/secrets.auto.tfvars"
```

**Features:** VNet, VMs, Key Vault RBAC, Bastion break-glass, Managed Disks

→ [Azure Deployment Guide](infrastructure/deployments/azure/README.md)

### GCP Deployment

```bash
cd infrastructure/deployments/gcp
terraform init
terraform plan -var-file="../../config/foundry.auto.tfvars" -var-file="../../config/secrets.auto.tfvars" -var="project_id=your-project-id"
terraform apply -var-file="../../config/foundry.auto.tfvars" -var-file="../../config/secrets.auto.tfvars" -var="project_id=your-project-id"
```

**Features:** Compute Engine, VPC, Cloud NAT, OS Login, Secret Manager, Cloud Monitoring

→ [GCP Deployment Guide](infrastructure/deployments/gcp/README.md)

### Hetzner Deployment

```bash
export HCLOUD_TOKEN="your-hetzner-token"
cd infrastructure/deployments/hetzner
terraform init
terraform plan -var-file="../../config/foundry.auto.tfvars" -var-file="../../config/secrets.auto.tfvars"
terraform apply -var-file="../../config/foundry.auto.tfvars" -var-file="../../config/secrets.auto.tfvars"
```

**Features:** Simple, cost-effective, EU-based, SSD volumes, straightforward management

→ [Hetzner Deployment Guide](infrastructure/deployments/hetzner/README.md)

## 📖 Common Operations

### View Infrastructure State

```bash
# AWS
cd infrastructure/deployments/aws
terraform state list
terraform state show aws_instance.foundry

# Azure
cd infrastructure/deployments/azure
terraform state list
terraform state show azurerm_linux_virtual_machine.foundry

# GCP
cd infrastructure/deployments/gcp
terraform state list
terraform state show google_compute_instance.foundry
```

### Access Instances

**AWS** (Systems Manager):

```bash
aws ssm start-session --target i-xxxxx --region us-east-1
```

**Azure** (Bastion or SSH):

```bash
az vm run-command invoke --resource-group rg-name --name vm-name --command-id RunShellScript --scripts "whoami"
```

**GCP** (OS Login):

```bash
gcloud compute ssh instance-name --zone us-central1-a
```

**Hetzner** (SSH):

```bash
ssh root@<public-ip>
```

### Monitor Foundry Container

```bash
# Connect to instance first, then:
docker ps
docker logs -f foundry
docker exec -it foundry bash
```

### Create Manual Backup

**AWS:**

```bash
aws ec2 create-snapshot --volume-id vol-xxxxx --description "LegendForge backup $(date)"
```

**Azure:**

```bash
az snapshot create --resource-group rg-name --name snapshot-name --source vault-id
```

**GCP:**

```bash
gcloud compute disks snapshot disk-name --snapshot-names=backup-$(date +%Y%m%d%H%M%S)
```

**Hetzner:**

```bash
hcloud volume create-backup <volume-id>
```

### Pause Deployment (Keep Data)

All platforms support spin-down via variable:

```bash
terraform apply -var="compute_enabled=false"   -var-file="../../config/foundry.auto.tfvars"   -var-file="../../config/secrets.auto.tfvars"
```

### Resume Deployment

```bash
terraform apply -var="compute_enabled=true"   -var-file="../../config/foundry.auto.tfvars"   -var-file="../../config/secrets.auto.tfvars"
```

### Destroy Infrastructure

```bash
terraform destroy   -var-file="../../config/foundry.auto.tfvars"   -var-file="../../config/secrets.auto.tfvars"
```

⚠️ **WARNING:** This deletes data volumes. Create snapshots first if needed.

## 🔐 Security Best Practices

1. **Secrets Management**
   - Store `secrets.auto.tfvars` in `.gitignore` (never commit)
   - Use cloud-native secret managers (Secrets Manager, Key Vault, Secret Manager)
   - Rotate credentials regularly

2. **Access Control**
   - Disable inbound SSH by default (break-glass only)
   - Use cloud-native access methods:
     - AWS: Systems Manager Session Manager
     - Azure: Bastion Host
     - GCP: OS Login
     - Hetzner: Firewall rules

3. **Encryption**
   - All disks encrypted at rest by default
   - HTTPS required for Foundry access
   - Cloudflare Tunnel provides TLS termination

4. **Networking**
   - No public ports exposed to Foundry (Tunnel ingress only)
   - Cloud NAT / firewalls restrict egress
   - VPC/VNet isolation

5. **Monitoring**
   - CloudWatch (AWS), Monitor (Azure), Cloud Monitoring (GCP)
   - VPC Flow Logs enabled where supported
   - Instance health checks

## 📊 Terraform Best Practices

This repository follows Terraform best practices:

- ✅ **Modular design**: Reusable modules for each cloud platform
- ✅ **Provider pinning**: Specific provider versions to avoid surprises
- ✅ **Naming conventions**: Consistent resource naming across platforms
- ✅ **Tagging**: Resources tagged with project, environment, and managed-by metadata
- ✅ **Outputs**: Meaningful outputs for integration with other tools
- ✅ **Documentation**: Clear operator guidance for multi-system deployments
- ✅ **Local values**: Repeated strings stored in locals for DRY principles
- ✅ **Variable validation**: Input validation with actionable error messages
- ✅ **Sensitive values**: Secrets marked sensitive to prevent logging

## 🐛 Troubleshooting

### Terraform Validation Errors

```bash
cd infrastructure/deployments/<platform>
terraform validate
```

### Provider Authentication Issues

**AWS:**

```bash
aws sts get-caller-identity  # Verify credentials
```

**Azure:**

```bash
az account show  # Verify subscription
```

**GCP:**

```bash
gcloud config list  # Verify project and auth
```

**Hetzner:**

```bash
export HCLOUD_TOKEN="your-token"
# Token is verified on first API call
```

### Instance Not Starting

Check cloud provider logs:

- AWS: CloudWatch Logs
- Azure: Diagnostics blade
- GCP: Cloud Logging / Serial port output
- Hetzner: SSH and check `/var/log/cloud-init-output.log`

### Foundry Container Won't Start

```bash
# SSH to instance
docker logs foundry

# Check free disk space
df -h

# Check free memory
free -h

# Restart container
docker restart foundry
```

### DNS / Cloudflare Issues

```bash
# Verify DNS resolution
dig vtt.yourdomain.com

# Check Cloudflare Tunnel status
cloudflared tunnel list
cloudflared tunnel status

# Verify tunnel token in container
docker exec foundry env | grep TUNNEL
```

## 📈 Monitoring & Maintenance

### Regular Backups

All platforms have automated backup schedules:

- AWS: Daily snapshots via AWS Backup
- Azure: Daily snapshots via Backup Vault
- GCP: Daily snapshots via Disk Resource Policy
- Hetzner: Manual backups (create via console)

### Disk Usage Monitoring

Monitor persistent volume usage:

```bash
ssh <instance> "df -h"
```

Expand volume if needed by updating `data_volume_size_gb`.

### Updates

Update Foundry by changing `foundry_image` in config and re-applying:

```bash
# Edit config/foundry.auto.tfvars
foundry_image = "felddy/foundryvtt@sha256:new-digest"

# Apply changes
terraform apply -var-file="../../config/foundry.auto.tfvars"                 -var-file="../../config/secrets.auto.tfvars"
```

### Multi-System Change Management

When switching or adding systems in Foundry:

1. Back up your world data first.
2. Verify the target system version is compatible with your Foundry release.
3. Introduce modules gradually and validate each world independently.
4. Document system-specific dependencies outside the infrastructure layer.

## 📚 Additional Resources

## ✅ Current TODO Backlog

Planned work items are tracked in **[TODO.md](TODO.md)**, organized into features, stories, and tasks for future implementation planning.

### Core Documentation

- [SUPPORTED_SYSTEMS.md](SUPPORTED_SYSTEMS.md) - System compatibility overview
- [PROJECT_PHILOSOPHY.md](PROJECT_PHILOSOPHY.md) - Universal tabletop infrastructure vision
- [ATTRIBUTION.md](ATTRIBUTION.md) - Technical attribution and license references
- [CREDITS.md](CREDITS.md) - Community recognition and acknowledgments
- [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md) - Documentation map
- [TODO.md](TODO.md) - Prioritized feature backlog with stories and tasks

### Official Documentation

- [Foundry VTT Docs](https://foundryvtt.com/article/installation/)
- [felddy/foundryvtt Docker Image](https://github.com/felddy/foundryvtt-docker) - ⭐ Thanks Felix!
- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)

### Cloud Provider Documentation

- [AWS Terraform Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [Azure Terraform Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
- [GCP Terraform Provider](https://registry.terraform.io/providers/hashicorp/google/latest)
- [Hetzner Cloud Terraform Provider](https://registry.terraform.io/providers/hetznercloud/hcloud/latest)

### Terraform Best Practices

- [Terraform AWS Best Practices](https://learn.hashicorp.com/terraform)
- [Terraform Module Best Practices](https://developer.hashicorp.com/terraform/language/modules/develop)

## 🙏 Attribution & Credits

LegendForge stands on the shoulders of giants. We gratefully use and credit:

- **[Foundry Virtual Tabletop](https://github.com/foundryvtt)** - The platform enabling many tabletop systems
- **[felddy/foundryvtt-docker](https://github.com/felddy/foundryvtt-docker)** - Essential Docker image maintained by @felddy
- **[Cloudflare Tunnel](https://www.cloudflare.com/products/tunnel/)** - Secure tunneling solution
- **[HashiCorp Terraform](https://www.terraform.io/)** - Infrastructure as Code platform
- **Cloud providers including AWS, Azure, GCP, and Hetzner** - Deployment flexibility across environments
- **[Docker](https://www.docker.com/)** - Container platform
- **[Ubuntu/Canonical](https://ubuntu.com/)** - Operating system and cloud-init ecosystem

📚 **Full Attribution:** See [ATTRIBUTION.md](ATTRIBUTION.md) for complete technical details.

👥 **Community Credits:** See [CREDITS.md](CREDITS.md) for recognition of contributors and maintainers.

## 📄 License

This Terraform configuration is provided as-is. See [LICENSE](LICENSE) for details.

## 🛡️ Code Quality and Security Gates

This repository uses **local git hooks** and **GitHub Actions** to enforce quality and security checks.

### Local Hooks (pre-commit + pre-push)

Install required tools:

```bash
# macOS
brew install terraform tflint trufflehog
python3 -m pip install --user pre-commit semgrep
```

Install hooks:

```bash
# Enforce repository-managed git hooks (blocks push on Semgrep/TruffleHog findings)
git config core.hooksPath .githooks

# Optional: pre-commit framework hooks
pre-commit install --hook-type pre-commit --hook-type pre-push
```

Run checks manually:

```bash
pre-commit run --all-files --hook-stage pre-commit
pre-commit run --all-files --hook-stage pre-push
```

What is enforced:

- `terraform fmt -check -recursive`
- `terraform validate` for each deployment directory
- `tflint` for each deployment directory
- `semgrep --config p/ci`
- `trufflehog` staged-file scan on commit and full repository scan on push

### CI Pipeline

After pushing to GitHub (`sodejm/LegendForge-CloudCampaigns`), the workflow at:

- `.github/workflows/quality-security.yml`

runs the same pre-commit and pre-push quality/security gates in CI.

## 🤝 Contributing

Contributions are welcome. Please:

1. Fork the repository
2. Create a feature branch
3. Add or update modules and documentation
4. Test on at least one platform
5. Preserve the LegendForge universal-tabletop positioning when editing docs
6. Submit a pull request

## ❓ FAQ

**Q: Is LegendForge only for D&D?**
A: No. LegendForge is intentionally system-agnostic infrastructure for Foundry deployments, including D&D 5e, Pathfinder, World of Darkness, Fate, PbtA, Forbidden Lands, GUMSHOE, and other compatible systems.

**Q: Can I migrate between platforms?**
A: Yes. Foundry data is stored on persistent volumes. Export data, back up the volume, and import to the new platform.

**Q: What's the expected monthly cost?**
A: See the overview table above. AWS/Azure are roughly $50-75, GCP is roughly $48-50, and Hetzner is roughly €6-8 depending on configuration.

**Q: How do I update Foundry?**
A: Change the `foundry_image` digest in config and re-apply Terraform.

**Q: Can I use this for production?**
A: Yes. All platforms include backups, monitoring, and security best practices. Follow cloud provider HA guidance for enterprise-style environments.

**Q: How do I access Foundry if Cloudflare is down?**
A: Cloudflare Tunnel is the primary ingress path. For break-glass operations, enable an administrative access path such as SSH or Bastion according to your provider model.

---

**Last Updated:** June 28, 2026
**Project Identity:** LegendForge - universal tabletop infrastructure for Foundry VTT
