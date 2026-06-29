# Architecture and Security

This page summarizes the repository's shared architecture themes across providers.

## Shared Architecture Pattern

LegendForge focuses on the same core domains across clouds:

- Compute for Foundry runtime
- Networking and controlled ingress
- Persistent storage
- Secret management
- Monitoring and alerting
- Backup and recovery support

## Security Defaults

LegendForge favors:

- Cloudflare Tunnel or equivalent controlled ingress
- Minimal public exposure
- Secret isolation in cloud-native stores where possible
- Break-glass access only when necessary
- Backup discipline before risky changes

## Why the Platform Stays System-Agnostic

LegendForge is infrastructure, not a rules implementation.

That means:

- Terraform provisions the hosting layer
- Foundry runs as the application platform
- Systems and modules are installed after deployment
- Documentation should stay useful for many game families

## Operational Durability

The repository emphasizes:

- Persistent storage for campaign artifacts
- Backup and restore planning
- Safe upgrade workflow expectations
- Documentation as an operator tool

## Provider Variations

- **AWS** emphasizes broader infrastructure building blocks and scaling patterns
- **Azure** emphasizes Azure-native access control and operations
- **GCP** emphasizes managed observability and managed services
- **Hetzner** emphasizes simplicity and cost control

## Related Sources

- [PROJECT_PHILOSOPHY.md](../PROJECT_PHILOSOPHY.md)
- [SUPPORTED_SYSTEMS.md](../SUPPORTED_SYSTEMS.md)
- [INFRASTRUCTURE_SUMMARY.md](../INFRASTRUCTURE_SUMMARY.md)
- [AWS_INFRASTRUCTURE_SUMMARY.md](../AWS_INFRASTRUCTURE_SUMMARY.md)
- [GCP_INFRASTRUCTURE_INDEX.md](../GCP_INFRASTRUCTURE_INDEX.md)
