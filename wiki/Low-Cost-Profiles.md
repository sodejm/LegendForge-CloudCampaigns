# Low-Cost Profiles

The [AWS](https://github.com/sodejm/LegendForge-CloudCampaigns/blob/main/infrastructure/deployments/aws-low-cost/README.md) and
[GCP](https://github.com/sodejm/LegendForge-CloudCampaigns/blob/main/infrastructure/deployments/gcp-low-cost/README.md) roots run Foundry
and Cloudflare Tunnel on one VM. They omit managed databases, load balancers,
NAT gateways and automatic backups. A protected, independent data disk survives
`paused=true`; disk storage remains billed. Complete first boot and a backup
before pausing, and verify the same disk ID after resuming.

[Hetzner](https://github.com/sodejm/LegendForge-CloudCampaigns/blob/main/infrastructure/deployments/hetzner/README.md) is another
single-server option. Its power-off still bills the server. Its Terraform
`compute_enabled=false` deletes the managed data volume and is never a safe pause.
Azure's reduced standard profile still includes substantial managed-service costs.

Use the [comparison and pricing assumptions](https://github.com/sodejm/LegendForge-CloudCampaigns/blob/main/docs/DEPLOYMENT_MODEL_COMPARISON.md)
to choose a profile, and follow [low-cost operations](https://github.com/sodejm/LegendForge-CloudCampaigns/blob/main/docs/LOW_COST_OPERATIONS.md)
for first boot, quiesced off-host backups, tested restore, reversible stop/start,
resize, upgrades, scheduling and retirement. No automatic scheduler or paid
backup service is provisioned. Keep one writer for state and the active world.

See [Provider Guide](Provider-Guide.md), [Quickstart](Quickstart.md), and
[validation evidence](https://github.com/sodejm/LegendForge-CloudCampaigns/blob/main/docs/TERRAFORM_VALIDATION.md).
