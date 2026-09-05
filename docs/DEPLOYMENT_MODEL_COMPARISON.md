# Deployment model comparison and cost baseline

This guide helps choose between the Terraform deployments currently maintained
in this repository. It is a planning aid, not a price quote or an uptime
guarantee. Select a provider and profile only after reviewing the generated
Terraform plan and the provider's current calculator for the intended account
and region.

## Scope and method

The comparison is derived from the Terraform defaults and module wiring in this
repository as of **2026-09-05**. It covers the deployments in
[`infrastructure/deployments/aws`](../infrastructure/deployments/aws),
[`azure`](../infrastructure/deployments/azure),
[`gcp`](../infrastructure/deployments/gcp), and
[`hetzner`](../infrastructure/deployments/hetzner). Licensing, support, taxes, and Cloudflare paid services are additional costs.

Each provider's “cost baseline” below is a configuration-derived bill of
materials (BOM), not a live price. Currency, region, and source are stated so
that the estimate can be reproduced. Before approval, price the exact planned
resources plus egress, requests, storage operations, observability retention,
backup retention, and any applicable support plan.

## At a glance

| Deployment | Default resource profile | Best fit | Main trade-off |
| --- | --- | --- | --- |
| AWS | Two-AZ VPC, two `t3.medium` application instances, Multi-AZ `db.t3.medium` RDS, ALB, CloudFront, S3, CloudWatch | Production workload where AWS managed HA, backups, and AWS operations are required | Highest service count and several persistent/network charges |
| Azure | VM scale set at two `Standard_D4s_v5` instances, flexible database at `GP_Standard_D2ds_v4`, private endpoints, Key Vault, storage/CDN, monitoring | Azure-standard identity, networking, and operations estate | High default compute footprint and many managed services |
| GCP | Two `n2-standard-2` application instances, Cloud SQL `db-custom-2-7680`, two 500 GB `pd-ssd` data disks (one per instance; at least 1 TB active), load balancer, CDN, Cloud Armor, monitoring | GCP environment needing private Cloud SQL, Google-managed edge controls, and optional multi-region design | Per-instance persistent disks and managed platform components materially affect spend |
| AWS low cost | One `t3.small`, 20 GB boot + 30 GB data gp3, SSM, Cloudflare Tunnel | Scheduled campaign on AWS | Single host, operator backups; stop preserves disks |
| GCP low cost | One `e2-small`, 20 GB boot + 30 GB data pd-balanced, IAP, Cloudflare Tunnel | Scheduled campaign on GCP | Shared CPU, operator backups; stop preserves disks |
| Hetzner | One `cx21` server, 20 GB attached volume, private network, Cloudflare Tunnel | Cost-sensitive single-server campaign with operator-managed recovery | No in-repository HA or managed database; recovery and capacity are operator responsibilities |

The first three are multi-service cloud deployments. Hetzner is deliberately a
single-server model. It should not be evaluated as an equivalent HA profile.

## Configuration-derived resource profiles

### AWS

The AWS deployment defaults to `us-east-1`, two availability zones, a two to
four instance auto-scaling group (desired capacity two), `t3.medium` compute,
and Multi-AZ PostgreSQL 15.3 on `db.t3.medium`. It configures 100 GB database
storage, 3,000 IOPS, 125 throughput units, and 30-day database backup
retention. The root deployment composes VPC, security groups, RDS, S3, IAM,
ALB, CloudFront, EC2 auto scaling, CloudWatch, and Route53 modules; ACM and
health checks are enabled by default.

Choose this model when multi-AZ database failover, an ALB/CloudFront entry
path, Route53 integration, and AWS-native operational tooling matter more than
a minimal bill. Private compute and database tiers reduce direct exposure, but
introduce egress and managed-network dependencies.

### Azure

The Azure deployment defaults to `eastus`, a two-instance VM scale set of
`Standard_D4s_v5` (minimum two, maximum ten), and a MySQL flexible server at
`GP_Standard_D2ds_v4` with 100 GB storage. It enables 35-day backups, geo-redundant
backup, database high availability, monitoring, and CDN by default. The
deployment composes networking, Key Vault-based security, private storage,
database, VM scale set/load balancer compute, and optional monitoring modules.

Choose this model when Azure resource governance, managed identity/Key Vault,
private endpoints, and Azure Monitor integration are primary requirements. The
production defaults favor resilience and managed controls, not the smallest
possible footprint.

### GCP

The GCP deployment defaults to `us-central1` with a `us-east1` secondary
region defined but `enable_multi_region = false`. It starts a managed instance
group at two `n2-standard-2` instances (maximum five), uses PostgreSQL 15
Cloud SQL at `db-custom-2-7680`, and provisions one 500 GB `pd-ssd` data disk
for every managed instance group member. The default minimum of two instances
therefore keeps at least 2 × 500 GB, or 1 TB, of active data disks. CDN and
Cloud Armor are enabled by default; Cloud SQL public IP is disabled and
deletion protection is enabled. The root composes VPC, IAM, secrets, Cloud SQL,
storage, compute, load balancing, and monitoring modules.

Choose this model when private managed database access, Google edge controls,
and GCP-native monitoring are required. Every additional active group member
adds another 500 GB `pd-ssd` disk, so the default maximum of five instances
uses 2.5 TB of active data disks at steady state. The proactive rolling-update
policy allows one surge instance, which can temporarily raise that total to six
disks, or 3 TB. These disks set `auto_delete = false`; retained disks from
scale-in, replacement, or a completed surge remain separately billable until
an operator removes them and are not included in the active-group total. The
active deployment configures no snapshot policy for these data disks, so any
operator-created snapshots are a separate storage cost rather than part of the
baseline. The default `admin_source_ranges` includes `0.0.0.0/0` and must be
narrowed before production use.

### Hetzner

The Hetzner deployment defaults to the `eu-central` network zone, `fsn1-dc14`,
a single `cx21` server (legacy default), and a 20 GB volume mounted at `/opt/foundry/data`. The provider now accepts
`location`: the legacy `fsn1-dc14` input maps to `fsn1`. For a new deployment,
review `location = "fsn1"` and `server_type = "cx23"`; capacity is not guaranteed.
`compute_enabled=false` deletes both the server and its managed data volume;
it is not a data-preserving compute switch. The module uses a private network
and optional break-glass SSH CIDR; the application is designed to use a
Cloudflare Tunnel for outward-facing access.

Choose this model for a simple, cost-sensitive service where a single host is
an acceptable availability boundary. It has no configured replicated database,
load balancer, autoscaling group, or multi-zone failover. Keep independent,
tested backups outside the server and plan maintenance around its single-host
outage domain.

## Cost baseline: how to estimate

The following standard-profile BOMs require a current calculator review for
their complete monthly totals. The low-cost section below provides dated,
partial estimates; provider prices, discounts, taxes, and service availability
vary by date, account, and region.

| Provider | Estimate region and currency | Source to use | Configuration-derived BOM |
| --- | --- | --- | --- |
| AWS | `us-east-1`; USD; review date 2026-09-05 | [AWS Pricing Calculator](https://calculator.aws/) | 2 `t3.medium` instances at desired capacity (allow 2–4), Multi-AZ `db.t3.medium`, 100 GB RDS storage, 3,000 IOPS/125 throughput, ALB, CloudFront, Route53, S3, CloudWatch, NAT/VPC networking, 30-day database/log retention |
| Azure | `eastus`; USD; review date 2026-09-05 | [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) | 2 `Standard_D4s_v5` VMSS instances (allow 2–10), `GP_Standard_D2ds_v4` flexible database with 100 GB, HA, geo-redundant backups, NAT/public IP/load balancer, DDoS Protection plan, Key Vault, private endpoints, storage/CDN, Log Analytics/Application Insights/alerts |
| GCP | `us-central1`; USD; review date 2026-09-05 | [Google Cloud Pricing Calculator](https://cloud.google.com/products/calculator) | 2 `n2-standard-2` instances (allow 2–5), at least 2 × 500 GB `pd-ssd` data disks (1 TB active at the default minimum; one per group member, up to 2.5 TB steady-state at five), plus one possible 500 GB rolling-update surge disk; `db-custom-2-7680` Cloud SQL, load balancer, CDN, Cloud Armor, NAT/VPC, storage, Secret Manager, monitoring/logging; retained non-auto-delete disks, including a completed surge disk, and any operator-created snapshots remain separate charges |
| Hetzner | `fsn1-dc14` / `eu-central`; EUR; review date 2026-09-05 | [Hetzner Cloud pricing](https://www.hetzner.com/cloud/) | 1 `cx21`, 20 GB volume, network/IP/traffic charges or allowances as applicable, plus external backup storage and Cloudflare services if used |

### Cost drivers and safe levers

| Area | Cost driver | Safe planning action | Trade-off to accept explicitly |
| --- | --- | --- | --- |
| Application capacity | Instance/VM count and type | Set a measured player/concurrency target before shrinking default capacity | Less headroom and slower recovery during spikes |
| Database | Managed DB size, HA, storage, IOPS, retention | Start from data size, RPO, and RTO; do not change HA solely to meet a budget | Lower availability or recovery capability |
| Network | NAT gateways, load balancers, CDN, egress, public IPs | Forecast normal and event-night traffic separately | Removing edge/network services can increase exposure or latency |
| Storage and backups | Data volume, snapshots, object versions, geo redundancy | Define retention and test restores before lifecycle reductions | Shorter rollback/recovery window |
| Observability | Logs, metrics, dashboards, alerts | Retain enough telemetry for incident investigation and chargeback | Reduced diagnosis and audit history |

## Comparable campaign and low-cost estimates

Planning workload: one Foundry world, five concurrent players, 2 vCPU and 2 GB
RAM minimum (4 GB recommended), 20 GB used data in a 30 GB allocation, 100 GB
monthly internet egress, and 30 GB off-host backup. Compare 730 running hours
against 40 active hours including startup, patching, and backups. These are
planning assumptions, not benchmarks; modules and media can require more RAM.
The standard profiles above provision substantially more resources than this
workload, so their total bills are not capacity-equivalent.

Prices checked **2026-09-05**, on-demand USD before tax/discounts/free credits.
The following are **partial monthly floors, not total bills**:

| Profile / region | 730 hours | 40 hours | Included calculation |
| --- | ---: | ---: | --- |
| AWS low cost / us-east-1 | $22.83 | $5.03 | t3.small $0.0208/h + active IPv4 $0.005/h + 50 GB gp3 at an illustrative $0.08/GB-month |
| GCP low cost / us-central1 | $20.88 | $5.87 | e2-small $0.016752855/h + active IPv4 $0.005/h + 50 GiB pd-balanced at $0.10/GiB-month |
| Hetzner / fsn1 | $6.49 compute cap | $6.49 compute cap | CX23 advertised monthly compute cap; powering off still bills the allocated server |
| Azure / eastus | Calculator required | Calculator required | No equivalent single-server Azure profile exists here; price the complete standard or reduced-standard BOM |

AWS sources: [T3 rates](https://docs.aws.amazon.com/prescriptive-guidance/latest/optimize-costs-microsoft-workloads/right-size-selection.html),
[EBS example rates](https://aws.amazon.com/ebs/pricing/),
[IPv4](https://aws.amazon.com/vpc/pricing/).
GCP sources: [Iowa compute](https://cloud.google.com/products/compute/pricing/general-purpose),
[disks](https://cloud.google.com/compute/disks-image-pricing),
[IPv4](https://cloud.google.com/vpc/network-pricing).
Hetzner source: [June 15, 2026 price adjustment](https://docs.hetzner.com/general/infrastructure-and-availability/price-adjustment/)
(CX23 FSN/NBG/HEL USD; EUR cap €5.49, IPv4 excluded).
Check [current capacity and pricing](https://www.hetzner.com/cloud/) before choosing a server.
Refresh all rates, currency, region, hours, disk sizes, and calculator exports
before deployment and at least quarterly. AWS gp3 is an illustrative published
rate; confirm the selected region's actual rate in the calculator.

Every estimate must also include these categories:

| Category | Standard AWS / Azure / GCP | AWS / GCP low cost | Hetzner |
| --- | --- | --- | --- |
| Compute | All minimum instances, surge/replacements, managed DB, HA replicas | One VM; 20 GB boot remains charged while stopped | One server remains billed while powered off |
| Storage | Boot/data disks, DB storage/IOPS, retained disks, buckets | 30 GB data remains charged while stopped; resize adds cost | Attached volume is additional to compute floor |
| Network | NAT hours/bytes, LB hours/requests, public IPs, CDN, DNS, egress | No NAT/LB/managed DB; ephemeral public IPv4 while running, internet egress | Public IP, volume and excess traffic charges/allowances must be added |
| Backups | DB retention, snapshots, object versions, cross-region copies; app backup gaps below | 30 GB off-host backup plus requests, retention and transfer; not provisioned | Off-host archive storage and transfer; not provisioned |
| Operations | Logs/metrics, secrets, security services (including Azure DDoS), support | Bounded local logs; optional external alerts/support | External monitoring/support |
| Shared extras | Foundry license, optional paid Cloudflare services, taxes | Same | Same |

Egress allowances are account-wide and can be consumed by other workloads;
100 GB assumed traffic does not establish a zero charge. Snapshots grow with
changed blocks and retention. Stopped VM disks, retained GCP standard group
disks, detached volumes, reserved IPs, and old environments keep billing.

AWS/GCP low-cost roots deliberately omit RDS/Cloud SQL, autoscaling, NAT,
load balancers, CDN, managed monitoring, and automatic backups. They run Foundry
and Cloudflare Tunnel together, with no public application listener. Both have
independent, protected data disks and an explicit `paused` variable. They require
a separately configured Tunnel route and a tested off-host restore. See
[low-cost operations](LOW_COST_OPERATIONS.md).

## Selection guide

Choose based on the operational outcome, not a single unit-price comparison:

| If this is the priority | Start with | Confirm before committing |
| --- | --- | --- |
| AWS organization standards, Multi-AZ RDS, Route53/CloudFront integration | AWS | Expected NAT, database, ALB, CDN, and retention charges; account/network governance |
| Azure identity, private endpoint, Key Vault, and Azure Monitor alignment | Azure | VMSS/database SKU availability in region; HA/geo-backup cost; private DNS and alert ownership |
| GCP-native Cloud SQL, Cloud Armor, and Google edge services | GCP | Required disk size, restricted admin CIDRs, Cloud SQL capacity, and whether multi-region is actually needed |
| Lowest always-on compute floor and one campaign-sized host | Hetzner, if capacity is available | Tested off-server restore, downtime tolerance, host sizing, and a secure administrator path |

For a scheduled campaign, choose AWS or GCP low cost when a retained-disk stop
fits your cloud account and admin skills. For always-on hosting, Hetzner has
the lowest quoted compute floor here, subject to IP/volume/backup charges and
capacity. Choose the standard AWS/Azure/GCP profile only when its managed
services justify the complete bill. Infrastructure redundancy does not prove
that multiple Foundry instances can safely serve one shared world: this
repository has not validated application failover, shared storage, or autoscaling
for that use. No production HA or recovery-time guarantee is implied.

## Security, availability, and recovery comparison

| Concern | AWS | Azure | GCP | Hetzner |
| --- | --- | --- | --- | --- |
| Application availability | ASG has a two-instance desired/minimum capacity behind ALB | VMSS starts at two behind load balancer | Managed instance group starts at two behind load balancer | One server; service interruption follows host maintenance/failure |
| Database availability | Multi-AZ RDS default | DB HA enabled by default | Managed Cloud SQL; multi-region is disabled by default | No managed database in this deployment |
| Secret handling | Sensitive Terraform inputs and IAM integration; review state handling | Key Vault security module and managed identity wiring | Secrets module and service-account IAM wiring | Sensitive variables; protect tfvars/state and host access |
| Network exposure | Private app/database tiers, security groups, ALB/CDN | NSGs, private endpoints, Key Vault/storage private DNS | Cloud SQL public IP disabled; firewall design requires restricted admin CIDRs | Tunnel-oriented ingress plus optional SSH CIDR; host remains the trust boundary |
| Recovery posture | RDS automated-backup retention and versioned S3 buckets; no scheduled application-volume snapshot in the active deployment | 35-day, geo-redundant Flexible Server backups and GZRS object storage by default; no blob versioning/soft delete or Recovery Services VM/disk backup in the active deployment | Cloud SQL automated backups/PITR and versioned Cloud Storage buckets; a daily cron archives `/opt/foundry/data` to the backups bucket, but it is a live file-level archive rather than an application-consistent disk snapshot, and no snapshot policy is attached | Operator must maintain and test independent off-server archives; Hetzner Server backups exclude the attached Volume |

Database backups and object-storage redundancy/versioning do not protect
application data stored on compute disks by themselves. The active Azure
deployment wires neither Recovery Services VM backup nor disk snapshots. The
active GCP deployment does provide a scheduled 02:00 archive of
`/opt/foundry/data` from each instance to the versioned backups bucket, but the
script does not quiesce the application, create a disk snapshot, verify the
upload, or exercise a restore. Treat Azure compute data as unprotected and the
GCP archive as a limited recovery path until each is explicitly implemented or
restore-tested to the required recovery objective.

Terraform state can contain sensitive values or resource metadata even when
variables are marked sensitive. Use a protected remote backend, least-privilege
credentials, encryption, and a secret-management workflow appropriate to the
provider. Never commit populated `terraform.tfvars`, state files, tunnel
tokens, license keys, or database credentials.

## Decision checklist

Before choosing a model, record these decisions with the deployment review:

1. Target provider, account/subscription/project, region, currency, and review
   date.
2. Expected concurrent players, data/media growth, normal egress, and
   peak-event egress.
3. Required availability window, acceptable single-host outage, RPO, and RTO.
4. Exact Terraform variable overrides from the defaults and why each protection
   or capacity setting is being changed.
5. Calculator export or estimate using the BOM above, including network,
   operations, backup, and support costs.
6. Administrator access CIDRs, secret storage, state backend, monitoring owner,
   and a tested restore procedure.

## Related deployment guides

- [AWS deployment README](../infrastructure/deployments/aws/README.md)
- [AWS deployment guide](../infrastructure/deployments/aws/DEPLOYMENT_GUIDE.md)
- [GCP deployment README](../infrastructure/deployments/gcp/README.md)
- [GCP deployment guide](../infrastructure/deployments/gcp/DEPLOYMENT_GUIDE.md)
- [Azure deployment configuration](../infrastructure/deployments/azure)
- [Hetzner deployment README](../infrastructure/deployments/hetzner/README.md)

## Migration and exit

Freeze writes and stop Foundry before creating an application-consistent archive.
Record Foundry, system and module versions; verify an encrypted off-host copy and
checksum. Restore into a separate destination environment/state, test a copy of
the world, validate ingress/admin access, then switch the hostname. Keep only one
writer for the live world. Check the Foundry license terms for overlapping servers.
For rollback, preserve the old environment until acceptance; reconcile any writes
before switching back. Budget transfer, temporary overlap, retained disks,
snapshots and DNS TTL. Retire the old resources only after a restore test and
retention decision; never use `terraform destroy` as a pause.

- [AWS low-cost guide](../infrastructure/deployments/aws-low-cost/README.md)
- [GCP low-cost guide](../infrastructure/deployments/gcp-low-cost/README.md)
- [Validation evidence](TERRAFORM_VALIDATION.md)
- [Documentation index](../DOCUMENTATION_INDEX.md)
- [Wiki low-cost profiles](../wiki/Low-Cost-Profiles.md)
