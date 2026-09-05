# Quickstart

Start with Terraform 1.7 or newer, the selected provider's CLI/credentials, a
valid Foundry license, and protected Terraform state. Choose one profile using
the [Provider Guide](Provider-Guide.md) and [Low-Cost Profiles](Low-Cost-Profiles.md).

1. Clone the repository and choose exactly one deployment directory.
2. Follow that directory's README to copy its own example variables and supply
   its required credentials. The shared `config/` examples are for Hetzner.
3. From that deployment directory, run `terraform init`, `terraform validate`,
   and `terraform plan -out=tfplan`.
4. Review the saved plan and complete cost before `terraform apply tfplan`.
5. Validate startup, hostname/TLS, admin access and a backup/restore before
   inviting players. Install compatible systems and modules inside Foundry.

Standard AWS/Azure/GCP use cloud load-balancer paths; Hetzner and AWS/GCP low
cost use a separately configured Cloudflare Tunnel. Inputs are not interchangeable.
A Terraform plan does not verify running Foundry or a recoverable world.

Use the [canonical README](https://github.com/sodejm/LegendForge-CloudCampaigns/blob/main/README.md) for all six profile links and commands.
See [Installation](Installation.md) and [How-To](How-To.md) for prerequisites
and operation, and [validation evidence](https://github.com/sodejm/LegendForge-CloudCampaigns/blob/main/docs/TERRAFORM_VALIDATION.md)
for the exact tested scope.
