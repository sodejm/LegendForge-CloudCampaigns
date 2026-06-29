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

- [AWS deployment README](../infrastructure/deployments/aws/README.md)
- [AWS deployment guide](../infrastructure/deployments/aws/DEPLOYMENT_GUIDE.md)
- [AWS architecture](../infrastructure/deployments/aws/ARCHITECTURE.md)
- [AWS quick reference](../infrastructure/deployments/aws/QUICK_REFERENCE.md)

## Azure

**Best for:** Azure-native administration, RBAC, and break-glass patterns

Repository guidance includes:

- Azure quick setup
- Key Vault and managed identity patterns
- VM scale set operations
- Monitoring and alerting guidance

Start with:

- [AZURE_QUICKSTART.md](../AZURE_QUICKSTART.md)
- [AZURE_DEPLOYMENT.md](../AZURE_DEPLOYMENT.md)
- [README_AZURE.md](../README_AZURE.md)

## GCP

**Best for:** managed services, observability, and global load-balancing features

Repository guidance includes:

- Cloud SQL HA
- Cloud Storage lifecycle policies
- Secret Manager and KMS
- Cloud Monitoring and Logging

Start with:

- [GCP deployment README](../infrastructure/deployments/gcp/README.md)
- [GCP deployment guide](../infrastructure/deployments/gcp/DEPLOYMENT_GUIDE.md)
- [GCP architecture](../infrastructure/deployments/gcp/ARCHITECTURE.md)
- [GCP quick reference](../infrastructure/deployments/gcp/QUICK_REFERENCE.md)

## Hetzner

**Best for:** low-cost hosting and simple operations

Repository guidance includes:

- Single-server deployment
- Persistent volume storage
- Cloudflare Tunnel-based ingress
- Low monthly cost profile

Start with:

- [Hetzner deployment README](../infrastructure/deployments/hetzner/README.md)

## Fast Selection Guide

Choose:

- **AWS** if you want stronger enterprise patterns and broader scale features
- **Azure** if your operations already live in Azure
- **GCP** if you want strong managed observability and GCP-native services
- **Hetzner** if cost is the main driver
