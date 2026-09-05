# Terraform validation evidence

Validation date: **2026-09-05**. This is local configuration and mock-provider
validation; no cloud resources were created, stopped, resized, or destroyed.
Live deployment, billing, Foundry startup, tunnel connectivity and disaster
recovery still require the operator's account and acceptance checks.

## Reproduce safely

Use Terraform 1.7 or newer (mock-provider tests require 1.7), TFLint, Python 3,
and pre-commit. The recorded local versions are Terraform **1.16.0** on
`darwin_arm64` and TFLint **0.64.0**. From the repository root:

```sh
scripts/terraform-quality.sh
python3 -m unittest discover -s tests -p 'test_*.py'
pre-commit run --all-files
pre-commit run --all-files --hook-stage pre-push
```

The quality script checks recursive formatting, initializes each root with
`-backend=false -input=false`, validates it, runs `terraform test` when tests
exist, and initializes/runs TFLint. Initialization downloads locked providers;
mock tests use synthetic inputs and do not need cloud credentials or call cloud
APIs. Keep real `terraform.tfvars` outside this test checkout. To narrow a run:

```sh
TERRAFORM_QUALITY_TARGETS=aws,azure,gcp,hetzner scripts/terraform-quality.sh
TERRAFORM_QUALITY_TARGETS=aws-low-cost,gcp-low-cost scripts/terraform-quality.sh
```

## Verified matrix

| Deployment | Locked provider | fmt / init / validate / TFLint | Mock plan coverage |
| --- | --- | --- | --- |
| AWS standard | aws 6.62.0 | Pass | Default topology |
| Azure standard | azurerm 5.3.0, random 3.9.0 | Pass | MySQL default topology |
| GCP standard | google / google-beta 7.46.0, random 3.9.0 | Pass | Default topology |
| Hetzner | hcloud 1.68.0 | Pass | Default topology, raw cloud-init, explicit location |
| AWS low cost | aws 6.63.0 | Pass | Running, paused/resized, rendered bootstrap |
| GCP low cost | google 7.46.1 | Pass | Running, paused/resized, rendered bootstrap |

The mock provider checks Terraform's graph and provider schema, not regional
SKU/image availability or API authorization. All fixtures use example domains
and synthetic credentials; Azure uses a public-only test RSA key. Standard AWS
uses raw user data, Azure uses base64 custom data, and Hetzner now uses raw
cloud-config beginning with `#cloud-config`. Low-cost bootstrap tests inspect
rendered configuration and independent disk references. Ten Python disk-preparation
tests cover blank disks, existing ext4, mounted/wrong disks, unknown signatures,
partitions, and refusal to overwrite an occupied target.

## Blocker reconciliation

The earlier tracked validation failures [#11](https://github.com/sodejm/LegendForge-CloudCampaigns/issues/11),
[#14](https://github.com/sodejm/LegendForge-CloudCampaigns/issues/14), and
[#18](https://github.com/sodejm/LegendForge-CloudCampaigns/issues/18) were already
closed when rechecked. They are not reopened or duplicated: the matrix above
rechecks the current roots and their active module interfaces.

The expanded mock plans exposed two additional compatibility problems:

- AzureRM 5.3.0 rejected the MySQL version `8.0` and database SKU
  `Standard_B2s`. Defaults/examples now use `8.0.21` and
  `GP_Standard_D2ds_v4`; disabling HA omits the block for both engine resources.
- hcloud 1.68.0 no longer supports the server's datacenter argument. The
  compatibility input maps to location, and the cloud-init contract now rejects
  base64 or a misplaced `#cloud-config` header.

Focused issues [#92 for Azure](https://github.com/sodejm/LegendForge-CloudCampaigns/issues/92)
and [#93 for Hetzner](https://github.com/sodejm/LegendForge-CloudCampaigns/issues/93)
record the reproduction commands, versions and observed failures under
validation umbrella [#50](https://github.com/sodejm/LegendForge-CloudCampaigns/issues/50).
The plan tests retain the regression checks.

## Operator acceptance before production

Follow the selected root's README for authentication and its own variable file.
Review an actual saved plan in the intended account; confirm region/quota,
current VM/database/image availability, service permissions and full cost BOM.
Protect remote state because sensitive values remain in state and user data.
Validate actual cloud-init completion, Foundry license/download, hostname/TLS,
administrator access, application health, a quiesced backup and restore, and a
pause/resume with the same data disk before depending on the service. Azure's
PostgreSQL option also needs subnet-delegation customization; only the MySQL
path is included in the standard fixture. No mock result establishes live HA,
capacity, an RPO/RTO, or a provider-specific operational guarantee.

See [comparison](DEPLOYMENT_MODEL_COMPARISON.md),
[low-cost operations](LOW_COST_OPERATIONS.md), and
[documentation index](../DOCUMENTATION_INDEX.md).
