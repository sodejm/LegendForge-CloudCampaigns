# Provider Guide

Use this page to decide which provider path matches your operational needs.

## AWS

**Best for:** enterprise patterns, scaling, and deeper AWS integrations

Common capabilities described in the repository:

- VPC networking
- EC2 and auto-scaling
- CloudWatch monitoring
- IAM roles and policies
- Persistent storage and backups

Start with:

- [AWS deployment README](https://github.com/sodejm/LegendForge-CloudCampaigns/blob/main/infrastructure/deployments/aws/README.md)
- [AWS deployment guide](https://github.com/sodejm/LegendForge-CloudCampaigns/blob/main/infrastructure/deployments/aws/DEPLOYMENT_GUIDE.md)
- [AWS architecture](https://github.com/sodejm/LegendForge-CloudCampaigns/blob/main/infrastructure/deployments/aws/ARCHITECTURE.md)
- [AWS quick reference](https://github.com/sodejm/LegendForge-CloudCampaigns/blob/main/infrastructure/deployments/aws/QUICK_REFERENCE.md)

## Azure

**Best for:** Azure-native administration, RBAC, and break-glass patterns

Repository guidance includes:

- Azure quick setup
- Key Vault and managed identity patterns
- VM scale set operations
- Monitoring and alerting guidance

Start with:

- [AZURE_QUICKSTART.md](https://github.com/sodejm/LegendForge-CloudCampaigns/blob/main/AZURE_QUICKSTART.md)
- [AZURE_DEPLOYMENT.md](https://github.com/sodejm/LegendForge-CloudCampaigns/blob/main/AZURE_DEPLOYMENT.md)
- [README_AZURE.md](https://github.com/sodejm/LegendForge-CloudCampaigns/blob/main/README_AZURE.md)

## GCP

**Best for:** managed services, observability, and global load-balancing features

Repository guidance includes:

- Cloud SQL HA
- Cloud Storage lifecycle policies
- Secret Manager and KMS
- Cloud Monitoring and Logging

Start with:

- [GCP deployment README](https://github.com/sodejm/LegendForge-CloudCampaigns/blob/main/infrastructure/deployments/gcp/README.md)
- [GCP deployment guide](https://github.com/sodejm/LegendForge-CloudCampaigns/blob/main/infrastructure/deployments/gcp/DEPLOYMENT_GUIDE.md)
- [GCP architecture](https://github.com/sodejm/LegendForge-CloudCampaigns/blob/main/infrastructure/deployments/gcp/ARCHITECTURE.md)
- [GCP quick reference](https://github.com/sodejm/LegendForge-CloudCampaigns/blob/main/infrastructure/deployments/gcp/QUICK_REFERENCE.md)

## Hetzner

**Best for:** low-cost hosting and simple operations

Repository guidance includes:

- Single-server deployment
- Persistent volume storage
- Cloudflare Tunnel-based ingress
- Low monthly cost profile

Start with:

- [Hetzner deployment README](https://github.com/sodejm/LegendForge-CloudCampaigns/blob/main/infrastructure/deployments/hetzner/README.md)

## Fast Selection Guide

Choose:

- **AWS** if you want stronger enterprise patterns and broader scale features
- **Azure** if your operations already live in Azure
- **GCP** if you want strong managed observability and GCP-native services
- **Hetzner** if cost is the main driver
