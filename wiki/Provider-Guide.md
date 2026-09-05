# Provider Guide

Compare the full monthly cost profile, availability and recovery responsibilities
in the [deployment comparison](https://github.com/sodejm/LegendForge-CloudCampaigns/blob/main/docs/DEPLOYMENT_MODEL_COMPARISON.md).
All paths need operator acceptance; mock validation is not a production guarantee.

## AWS

Choose [standard AWS](https://github.com/sodejm/LegendForge-CloudCampaigns/blob/main/infrastructure/deployments/aws/README.md) for its
managed network/database topology, or [AWS low cost](https://github.com/sodejm/LegendForge-CloudCampaigns/blob/main/infrastructure/deployments/aws-low-cost/README.md)
for one campaign server with SSM administration and retained-disk pause.

## Azure

Use the [canonical Azure guide](https://github.com/sodejm/LegendForge-CloudCampaigns/blob/main/infrastructure/deployments/azure/README.md)
for the active VM scale set and MySQL deployment. Its reduced standard profile
still provisions NAT, DDoS Protection and managed services; it is not equivalent
to the AWS/GCP low-cost roots. Root-level legacy Azure documents describe older
paths and are secondary references.

## GCP

Choose [standard GCP](https://github.com/sodejm/LegendForge-CloudCampaigns/blob/main/infrastructure/deployments/gcp/README.md) for managed
Cloud SQL and edge services, or [GCP low cost](https://github.com/sodejm/LegendForge-CloudCampaigns/blob/main/infrastructure/deployments/gcp-low-cost/README.md)
for a single VM with IAP/OS Login and retained-disk pause.

## Hetzner

The [Hetzner guide](https://github.com/sodejm/LegendForge-CloudCampaigns/blob/main/infrastructure/deployments/hetzner/README.md) covers a
single server with an attached volume and operator-managed backups. Confirm
current server availability. Power-off remains billed, and `compute_enabled=false`
deletes both the server and managed volume.

## Next steps

- [Quickstart](Quickstart.md)
- [Low-Cost Profiles](Low-Cost-Profiles.md)
- [How-To](How-To.md)
