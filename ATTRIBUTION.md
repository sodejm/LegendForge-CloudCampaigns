# LegendForge Attribution & Credits

LegendForge builds on the excellent work of the Foundry VTT, cloud, and open-source communities. This document acknowledges the projects, developers, and vendors that make **LegendForge universal tabletop infrastructure** possible.

---

## 🧭 LegendForge Mission Context

LegendForge is the rebranded identity of the `LegendForge-CloudCampaigns` repository. The infrastructure is designed to be:

- **Foundry-first** rather than tied to a single tabletop ruleset
- **System-agnostic** so operators can host many game systems
- **Cloud-portable** across AWS, Azure, GCP, and Hetzner
- **Security-focused** with tunneling, secrets management, and operational guardrails

LegendForge does **not** bundle proprietary game content or system-specific code in this repository. Instead, it delivers infrastructure that can host Foundry environments for many communities and campaign styles.

---

## 🎲 Primary Platform Dependencies

### Foundry Virtual Tabletop
- **Website:** https://foundryvtt.com/
- **GitHub:** https://github.com/foundryvtt
- **License:** Proprietary (commercial license required)
- **Description:** Core virtual tabletop platform deployed by LegendForge
- **Credits:** Foundry VTT team for creating a flexible platform that supports many tabletop systems

### felddy/foundryvtt Docker Image
- **GitHub:** https://github.com/felddy/foundryvtt-docker
- **Docker Hub:** https://hub.docker.com/r/felddy/foundryvtt
- **License:** MIT
- **Maintainer:** Felix Fontein (@felddy)
- **Description:** Dockerized Foundry VTT image used by LegendForge deployment workflows
- **Credits:** Huge thanks to Felix Fontein for maintaining this essential image and simplifying secure Foundry operations

---

## 🌐 Infrastructure, Networking, and Security

### Cloudflare Tunnel
- **Website:** https://www.cloudflare.com/products/tunnel/
- **Documentation:** https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/
- **License:** Proprietary (free tier available)
- **Docker Image:** https://hub.docker.com/r/cloudflare/cloudflared
- **Description:** Secure ingress without exposing Foundry directly to the public internet
- **Credits:** Cloudflare for providing zero-trust networking that aligns with LegendForge security goals

### HashiCorp Vault (Referenced Architecture)
- **Website:** https://www.vaultproject.io/
- **License:** BSL 1.1
- **Description:** Referenced as part of secure secret-management patterns used in the project documentation

---

## 📦 Infrastructure as Code Tooling

### Terraform
- **Website:** https://www.terraform.io/
- **GitHub:** https://github.com/hashicorp/terraform
- **License:** BSL 1.1
- **Maintainer:** HashiCorp
- **Description:** Infrastructure as Code engine used to define LegendForge cloud resources declaratively
- **Credits:** HashiCorp for the tooling that makes reproducible multi-cloud infrastructure possible

### Terraform Providers

#### AWS Provider
- **Registry:** https://registry.terraform.io/providers/hashicorp/aws/latest
- **GitHub:** https://github.com/hashicorp/terraform-provider-aws
- **License:** MPL 2.0
- **Maintainer:** HashiCorp
- **Description:** Official AWS provider used by LegendForge AWS deployments

#### Azure Provider (AzureRM)
- **Registry:** https://registry.terraform.io/providers/hashicorp/azurerm/latest
- **GitHub:** https://github.com/hashicorp/terraform-provider-azurerm
- **License:** MPL 2.0
- **Maintainer:** HashiCorp
- **Description:** Official Azure Resource Manager provider used by LegendForge Azure deployments

#### GCP Provider
- **Registry:** https://registry.terraform.io/providers/hashicorp/google/latest
- **GitHub:** https://github.com/hashicorp/terraform-provider-google
- **License:** MPL 2.0
- **Maintainer:** HashiCorp
- **Description:** Official Google Cloud provider used by LegendForge GCP deployments

#### Hetzner Cloud Provider
- **Registry:** https://registry.terraform.io/providers/hetznercloud/hcloud/latest
- **GitHub:** https://github.com/hetznercloud/terraform-provider-hcloud
- **License:** MIT
- **Maintainer:** Hetzner
- **Description:** Official Hetzner Cloud provider used by LegendForge Hetzner deployments
- **Credits:** Hetzner for maintaining a high-quality provider and affordable infrastructure option

#### Random Provider
- **Registry:** https://registry.terraform.io/providers/hashicorp/random/latest
- **License:** MPL 2.0
- **Maintainer:** HashiCorp
- **Description:** Provider for generating random values used in naming and secret-adjacent configuration patterns

---

## ☁️ Cloud Platforms Referenced by LegendForge

### Amazon Web Services (AWS)
- **Website:** https://aws.amazon.com/
- **Terraform Docs:** https://docs.aws.amazon.com/terraform/
- **Services Used:**
  - EC2 (compute)
  - VPC (networking)
  - RDS (database-ready patterns)
  - S3 (object storage)
  - CloudFront (CDN)
  - IAM (identity)
  - CloudWatch (monitoring)
  - Systems Manager (access management)
  - Elastic Load Balancer (load balancing)
  - Route 53 (DNS)
  - Secrets Manager (secrets)

### Microsoft Azure
- **Website:** https://azure.microsoft.com/
- **Terraform Docs:** https://learn.microsoft.com/en-us/azure/developer/terraform/
- **Services Used:**
  - Virtual Machines (compute)
  - Virtual Networks (networking)
  - Azure Database for MySQL/PostgreSQL (database-ready patterns)
  - Blob Storage (object storage)
  - Key Vault (secrets and keys)
  - Application Gateway / Load Balancer (load balancing)
  - Network Security Groups (firewalls)
  - Application Insights / Azure Monitor (monitoring)
  - Managed Disks (block storage)
  - RBAC (identity and access control)

### Google Cloud Platform (GCP)
- **Website:** https://cloud.google.com/
- **Terraform Docs:** https://cloud.google.com/docs/terraform
- **Services Used:**
  - Compute Engine (VMs)
  - Virtual Private Cloud (VPC)
  - Cloud SQL (managed database)
  - Cloud Storage (object storage)
  - Cloud CDN (content delivery)
  - Cloud IAM (identity)
  - Cloud Monitoring (observability)
  - Secret Manager (secrets)
  - Cloud Load Balancing (load balancing)

### Hetzner Cloud
- **Website:** https://www.hetzner.cloud/
- **API Docs:** https://docs.hetzner.cloud/
- **Services Used:**
  - Cloud Servers (compute)
  - Cloud Networks (networking)
  - Volumes (block storage)
  - Firewalls (network security)

---

## 🔧 System Tools & Runtime Dependencies

### Docker
- **Website:** https://www.docker.com/
- **GitHub:** https://github.com/moby/moby
- **License:** Apache 2.0 & Proprietary
- **Description:** Container runtime for Foundry and supporting services
- **Credits:** Docker for revolutionizing portable application delivery

### Cloud-Init
- **Website:** https://cloud-init.io/
- **GitHub:** https://github.com/canonical/cloud-init
- **License:** GPL v3
- **Description:** Instance initialization framework used for bootstrapping LegendForge workloads
- **Credits:** Canonical for maintaining essential cloud provisioning tooling

### Ubuntu Linux
- **Website:** https://ubuntu.com/
- **GitHub:** https://github.com/ubuntu
- **License:** Various OSS licenses
- **Description:** Default operating system base for LegendForge VM instances
- **Credits:** Canonical for a stable and well-supported cloud operating system

---

## 🎯 Supported-System Positioning

LegendForge documentation explicitly supports Foundry deployments for many tabletop systems, including but not limited to:

- Dungeons & Dragons 5e
- Pathfinder 1e and Pathfinder 2e
- World of Darkness / Storyteller-family games
- Fate variants
- Powered by the Apocalypse games
- Forbidden Lands
- GUMSHOE-based games
- Other Foundry-compatible systems

📚 Detailed compatibility notes live in [SUPPORTED_SYSTEMS.md](SUPPORTED_SYSTEMS.md).

---

## 📚 Documentation & Reference Material

### LegendForge Documentation
- [README.md](README.md) - Primary project overview
- [SUPPORTED_SYSTEMS.md](SUPPORTED_SYSTEMS.md) - Compatible system overview
- [PROJECT_PHILOSOPHY.md](PROJECT_PHILOSOPHY.md) - Universal infrastructure philosophy
- [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md) - Navigation guide

### External Documentation
- Terraform Docs: https://developer.hashicorp.com/terraform
- Terraform Registry: https://registry.terraform.io/
- AWS Docs: https://docs.aws.amazon.com/
- Azure Docs: https://learn.microsoft.com/en-us/azure/
- GCP Docs: https://cloud.google.com/docs
- Hetzner Docs: https://docs.hetzner.cloud/

---

## 🤝 Community Contributors and Ecosystem Thanks

Special thanks to:

1. **The Foundry VTT Community** - For creating an expansive ecosystem of systems, modules, worlds, and operational knowledge
2. **The Terraform Community** - For modules, examples, and multi-cloud best practices
3. **Cloud Community Forums** - For troubleshooting guidance and architecture discussions
4. **Open Source Maintainers** - For the tools that make modern infrastructure possible

---

## 📝 License Compliance

LegendForge respects all dependency licenses and usage requirements:

- **Terraform & HashiCorp Providers:** BSL 1.1 / MPL 2.0
- **Hetzner Provider:** MIT
- **Docker:** Apache 2.0
- **Cloud-Init:** GPL v3
- **Ubuntu:** Various OSS licenses
- **Foundry VTT:** Commercial license required

When deploying this infrastructure, ensure you:
- ✅ Have a valid Foundry VTT license
- ✅ Follow the terms of service for each cloud platform
- ✅ Comply with all open-source licenses
- ✅ Respect licensing and access rules for any system or content installed inside Foundry

---

## 🔗 Quick Links

| Resource | Purpose | Link |
|----------|---------|------|
| Foundry VTT | Virtual tabletop platform | https://foundryvtt.com/ |
| felddy/foundryvtt | Docker image | https://github.com/felddy/foundryvtt-docker |
| Cloudflare Tunnel | Secure ingress | https://developers.cloudflare.com/cloudflare-one/ |
| Terraform | IaC tool | https://www.terraform.io/ |
| AWS | Cloud provider | https://aws.amazon.com/ |
| Azure | Cloud provider | https://azure.microsoft.com/ |
| GCP | Cloud provider | https://cloud.google.com/ |
| Hetzner | Cloud provider | https://www.hetzner.cloud/ |
| Docker | Container runtime | https://www.docker.com/ |
| Ubuntu | Operating system | https://ubuntu.com/ |

---

## 📢 Feedback & Corrections

If you believe any attribution is missing or incorrect, please:
1. Check this file for existing entries
2. Review the repository documentation
3. Submit a pull request with corrections
4. Or open an issue with details

We want to ensure all contributors and projects are properly credited.

---

**Last Updated:** June 28, 2026<br>
**LegendForge Focus:** Universal tabletop infrastructure for Foundry-compatible systems
