# Installation

Install Terraform 1.7 or newer and the CLI for the selected cloud (`aws`, `az`,
or `gcloud`). Hetzner requires an API token. Prepare a Foundry license and
administrator key; download credentials or a release URL depend on the profile.

## Configuration and credentials

Use the selected directory's canonical README and examples. Standard AWS,
Azure, GCP and the two low-cost roots have different variable schemas. Only
Hetzner consumes the shared `config/` examples. Supply its provider token with
`TF_VAR_hcloud_token`; do not assume a different environment variable overrides
the explicitly configured Terraform token.

AWS requires a configured identity, Azure a selected subscription and public SSH
key, and GCP a billing-enabled project, enabled APIs and application-default
credentials or an approved service identity. Each guide states the exact flow.
Never commit populated tfvars, plans, state, tunnel tokens or license credentials.
Use an encrypted, access-controlled remote state backend for an operated service.

## Ingress

Hetzner and AWS/GCP low cost require an existing Cloudflare Tunnel token and
published route, with optional Access policy configured separately. For the
low-cost roots, route to `http://foundry:30000`. They do not create Cloudflare
DNS or Access policies. Standard AWS/Azure/GCP use their own networking and
load-balancer configuration; review each guide's TLS limitations.

## Validate first

Read the [validation record](https://github.com/sodejm/LegendForge-CloudCampaigns/blob/main/docs/TERRAFORM_VALIDATION.md), then follow
[Quickstart](Quickstart.md) and the [Provider Guide](Provider-Guide.md).
For low-cost backup, stop, restore and resize procedures see
[Low-Cost Profiles](Low-Cost-Profiles.md).
