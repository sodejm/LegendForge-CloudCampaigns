# Use Cases

LegendForge is built for operators who need stable Foundry infrastructure without tying the platform to one game system.

## Single Private Campaign

Good fit when you need:

- One secure Foundry instance
- Persistent world storage
- Backup discipline before upgrades
- A simple but production-minded deployment path

Strong provider options:

- Hetzner for cost efficiency
- GCP for managed services

## Multi-System Community Server

Good fit when you need:

- One operational model for many systems
- Clear separation between infrastructure and game content
- Documentation that works across fantasy, horror, and narrative games
- Controlled upgrade and module workflows

Important practices:

- Track system-specific modules outside Terraform
- Validate module stacks per world
- Segment high-divergence communities when needed

## Long-Running Campaign Archive

Good fit when you need:

- Persistent storage for journals, maps, actors, and handouts
- Safe upgrade workflows
- Backup and recovery planning
- Stable remote administration

## Enterprise or Team-Managed Hosting

Good fit when you need:

- Role-based administration
- Cloud-native secrets handling
- Monitoring and alerting
- Repeatable infrastructure changes

Strong provider options:

- AWS
- Azure
- GCP

## Budget-Conscious Hosting

Good fit when you need:

- Low recurring cost
- Minimal complexity
- Spin-up and spin-down control
- Enough persistence to preserve worlds between compute cycles

Strong provider option:

- Hetzner

## Shared Community or Club Environment

Good fit when you need:

- Multiple worlds under a common hosting pattern
- Durable storage and clear operations
- Cloud portability
- Documentation that remains useful even as game systems change

## Migration-Friendly Hosting

Good fit when you need:

- The ability to change providers later
- Stable Foundry operations independent of the installed ruleset
- Documentation that explains provider differences without changing the project mission

## Summary

LegendForge works best wherever the infrastructure must stay dependable while **campaigns, systems, worlds, and communities evolve over time**.
