# LegendForge Wiki

LegendForge is **universal, production-ready Terraform infrastructure for Foundry VTT** across AWS, Azure, GCP, and Hetzner.

It is designed to support **many Foundry-compatible systems** without locking the infrastructure to a single ruleset.

## Start Here

If you are new to LegendForge, read these pages in order:

1. [Quickstart](Quickstart)
2. [Installation](Installation)
3. [Provider Guide](Provider-Guide)
4. [How-To](How-To)
5. [Use Cases](Use-Cases)

## What LegendForge Covers

- Multi-cloud Foundry VTT deployment
- Cloudflare Tunnel-first ingress
- Persistent storage and backups
- Security-first operator workflows
- Multi-system hosting guidance
- Provider-specific deployment paths

## Supported Platforms

| Platform | Best For | Status |
| --- | --- | --- |
| AWS | Enterprise and scalability | Complete |
| Azure | Enterprise RBAC and Azure-native operations | Complete |
| GCP | Simplicity and monitoring | Complete |
| Hetzner | Low-cost EU hosting | Complete |

## Core Ideas

- **System-agnostic by default**: LegendForge hosts Foundry, not a single ruleset
- **Foundry-compatible**: game systems are installed inside Foundry after deployment
- **Cloud-neutral where it matters**: similar operational model across providers
- **Secure by default**: minimal public exposure, secret isolation, controlled access
- **Durable operations**: backups, persistent storage, and recovery planning matter

## Recommended Reading Paths

### New operators

1. [Quickstart](Quickstart)
2. [Installation](Installation)
3. [Use Cases](Use-Cases)

### Deployment operators

1. [Provider Guide](Provider-Guide)
2. [Architecture and Security](Architecture-and-Security)
3. [How-To](How-To)

### Contributors and reviewers

1. [Prompts](Prompts)
2. [Architecture and Security](Architecture-and-Security)
3. Repository docs linked below

## Key Repository Documents

- [README.md](https://github.com/sodejm/LegendForge-CloudCampaigns/blob/main/README.md)
- [DOCUMENTATION_INDEX.md](https://github.com/sodejm/LegendForge-CloudCampaigns/blob/main/DOCUMENTATION_INDEX.md)
- [PROJECT_PHILOSOPHY.md](https://github.com/sodejm/LegendForge-CloudCampaigns/blob/main/PROJECT_PHILOSOPHY.md)
- [SUPPORTED_SYSTEMS.md](https://github.com/sodejm/LegendForge-CloudCampaigns/blob/main/SUPPORTED_SYSTEMS.md)
- [AWS deployment docs](https://github.com/sodejm/LegendForge-CloudCampaigns/blob/main/infrastructure/deployments/aws/README.md)
- [GCP deployment docs](https://github.com/sodejm/LegendForge-CloudCampaigns/blob/main/infrastructure/deployments/gcp/README.md)
- [Hetzner deployment docs](https://github.com/sodejm/LegendForge-CloudCampaigns/blob/main/infrastructure/deployments/hetzner/README.md)
- [Azure quickstart](https://github.com/sodejm/LegendForge-CloudCampaigns/blob/main/AZURE_QUICKSTART.md)
- [Azure deployment guide](https://github.com/sodejm/LegendForge-CloudCampaigns/blob/main/AZURE_DEPLOYMENT.md)

## Summary

LegendForge gives operators **one infrastructure platform for many tabletop worlds**. Choose your cloud, deploy Foundry securely, then install the systems and content your community needs.
