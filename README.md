# LegendForge Multi-Cloud Infrastructure for Foundry VTT

![LegendForge Logo](resources/LegendForge_Logo.png)

LegendForge is a universal, production-minded **Terraform infrastructure platform** for deploying Foundry VTT across multiple cloud providers with security-first defaults, provider-specific recovery controls, and support for many tabletop game systems.

## 📋 Overview

LegendForge provides modular infrastructure for teams and game masters who want to run **Foundry VTT as system-agnostic tabletop infrastructure** instead of a single-ruleset deployment.

Choose a deployment profile before configuring Terraform:

| Profile | Topology | Operator guide |
| --- | --- | --- |
| AWS low cost | One EC2 instance, retained EBS data disk, reversible stop/start | [AWS low cost](infrastructure/deployments/aws-low-cost/README.md) |
| GCP low cost | One Compute Engine instance, retained persistent disk, reversible stop/start | [GCP low cost](infrastructure/deployments/gcp-low-cost/README.md) |
| Hetzner | One server and attached volume; operator-managed recovery | [Hetzner](infrastructure/deployments/hetzner/README.md) |
| AWS standard | Auto Scaling, RDS, NAT, ALB, CloudFront | [AWS standard](infrastructure/deployments/aws/README.md) |
| Azure standard | VM scale set, managed database, NAT, load balancer | [Azure canonical guide](infrastructure/deployments/azure/README.md) |
| GCP standard | Managed instance group, Cloud SQL, NAT, load balancer | [GCP standard](infrastructure/deployments/gcp/README.md) |

See the [deployment and cost comparison](docs/DEPLOYMENT_MODEL_COMPARISON.md) for a common workload, priced components, exclusions, and reliability trade-offs. Configuration validation and mock lifecycle tests are recorded in [Terraform validation](docs/TERRAFORM_VALIDATION.md); they do not establish live cloud readiness or Foundry world availability.

LegendForge supports **any Foundry-compatible tabletop system**. Systems, worlds, and modules are installed and validated inside Foundry after deployment.

## 🎲 Multi-System Support

LegendForge is built for campaigns and communities running multiple systems side by side, including:

- **Dungeons & Dragons 5e**
- **Pathfinder 1e and Pathfinder 2e**
- **World of Darkness** titles such as Vampire, Werewolf, Hunter, and related Storyteller games
- **Fate** variants including Core, Accelerated, and Condensed
- **Powered by the Apocalypse** games
- **Forbidden Lands**
- **GUMSHOE**-based games
- Additional Foundry-compatible systems, worlds, and modules

📚 See **[SUPPORTED_SYSTEMS.md](SUPPORTED_SYSTEMS.md)** for the full compatibility overview.

## 🧭 Project Philosophy

LegendForge treats Foundry as **universal tabletop infrastructure**:

- Infrastructure should be **agnostic to rulesets and genres**
- Security, backups, and observability should meet each campaign's requirements even when provider implementations differ
- Cloud architecture should be **portable across providers**
- Documentation should help operators run one world or many worlds with confidence
- The platform should scale from a home game to a multi-campaign community

📖 See **[PROJECT_PHILOSOPHY.md](PROJECT_PHILOSOPHY.md)** for the full philosophy statement.

## 🎯 Key Features

- System-agnostic Foundry infrastructure across four cloud providers.
- Separate low-cost and standard profiles with documented resource and recovery ownership.
- AWS/GCP low-cost profiles use Cloudflare Tunnel, independent data disks, and declarative pause/resume.
- Standard profiles expose different networking, secrets, monitoring, and scaling controls; consult each guide.
- Provider locks, validation, mock plans, acceptance tests, and security gates support repeatable review.

## 📁 Repository Structure

```text
infrastructure/
  deployments/{aws,azure,gcp,hetzner}/   # Standard/provider-specific roots
  deployments/{aws-low-cost,gcp-low-cost}/
  modules/foundry-app/                 # Existing shared application bootstrap
  modules/foundry-single-server/       # Retained-disk low-cost bootstrap
  modules/{aws,azure,gcp,providers}/
config/                               # Legacy Hetzner inputs
scripts/                              # Quality gates, backups, smoke test, Wiki sync
wiki/                                 # Canonical published Wiki sources
```

## 🚀 Quick Start

### Prerequisites

Install [Terraform 1.7 or later](https://developer.hashicorp.com/terraform/install), the selected provider CLI, and its credentials. Local quality checks also need Python 3, TFLint, pre-commit, Semgrep, and TruffleHog. See [validation prerequisites](docs/TERRAFORM_VALIDATION.md).

Prepare a valid Foundry license, download credentials, a strong setup password, and a public hostname. Tunnel profiles require an existing Cloudflare tunnel and hostname route; standard load-balancer profiles have additional provider-specific DNS and certificate inputs. Verify Foundry, system, module, and image compatibility before choosing versions.

### Configuration

Start at the repository root and follow **one** profile guide from the table above. AWS, Azure, GCP, and both low-cost roots have their own `terraform.tfvars.example`; copy it to `terraform.tfvars` inside the selected root and replace every placeholder. AWS standard also uses its own secrets example as described in its guide. GCP's project input is `gcp_project_id`. The legacy `config/*.auto.tfvars` flow is specific to Hetzner and is not interchangeable with these root inputs.

Keep credentials, variable files, state, saved plans, and backups private. `sensitive = true` hides ordinary Terraform display; it does not encrypt state or instance metadata. Use an encrypted, access-controlled state backend with locking before collaborating. Never run two writers against the same state.

Run `terraform init`, `terraform validate`, and `terraform plan -out=deployment.tfplan` in the chosen root. Review the complete plan, costs, public access, and data lifecycle before `terraform apply deployment.tfplan`, which provisions billable resources. Apply only a freshly reviewed plan.

## 🗺️ Choosing a Game System

LegendForge does not hard-code a single ruleset into the infrastructure. After Foundry is online, install the system and content you need inside Foundry itself.

Recommended operator workflow:

1. Deploy LegendForge infrastructure on your preferred cloud.
2. Confirm the Foundry instance is healthy and reachable through the selected profile's ingress.
3. Install your desired Foundry game system.
4. Restore or create worlds for one or more campaigns.
5. Add system-specific modules only after validating core platform stability.

For guidance on common system families, see **[SUPPORTED_SYSTEMS.md](SUPPORTED_SYSTEMS.md)**.

## 🎯 Platform Deployment Guides

Use the profile links in the overview. The [Azure deployment README](infrastructure/deployments/azure/README.md) is the canonical Azure setup and operations guide; older top-level Azure documents are supplementary. Do not combine commands from different deployment directories or reuse their state.

## 📖 Common Operations

### View Infrastructure State

In your chosen deployment directory, run `terraform state list` and inspect only the returned resource addresses with `terraform state show`. Standard deployments manage scale sets/groups; their addresses differ from the single-instance low-cost profiles. State details can contain secrets.

### Access Instances

AWS uses Systems Manager Session Manager. Azure standard uses VM scale set operations (`az vmss`, with a selected instance ID), not standalone `az vm` commands. GCP low cost uses OS Login through IAP. Hetzner SSH requires an explicitly permitted administration CIDR. Each guide lists its access prerequisites.

### Back Up, Pause, Resize, and Upgrade

For AWS/GCP low cost, follow [shared operations](docs/LOW_COST_OPERATIONS.md). Back up the actual Foundry data directory, store an encrypted copy off-host, and rehearse a restore. Managed database backups in standard profiles do not back up Foundry's world files.

Low-cost `paused=true` stops compute while retaining the VM identity and disks. Storage and backup charges remain. Wait for initial bootstrap and verify the mount before the first pause. Resize and image changes require a reviewed maintenance plan.

For Hetzner, `compute_enabled=false` deletes the server **and** its managed data volume. It is not a data-preserving pause. Use the [Hetzner lifecycle guide](infrastructure/deployments/hetzner/README.md#pause-and-resume), including its billing and off-server backup requirements. Destruction is a separate, reviewed retirement operation for every profile.

### Post-Deployment Reachability Smoke Test

After `terraform apply`, verify the public deployment URL with the
provider-neutral smoke test **from the repository root**:

```bash
# Read only the foundry_url output from the selected deployment directory.
scripts/post-deploy-smoke-test.sh infrastructure/deployments/gcp

# An explicit URL takes precedence over Terraform discovery.
FOUNDRY_URL=https://vtt.example.com scripts/post-deploy-smoke-test.sh
```

Without an argument, the deployment directory defaults to the current directory.
`TIMEOUT` controls the curl connection and request timeout in seconds (default
`10`), and `MAX_LATENCY_MS` sets the response-time budget (default `5000`).

The script validates the URL and hostname, resolves DNS names (while correctly
skipping DNS for literal IP addresses), requires normal certificate validation
for HTTPS, and accepts only HTTP 2xx or 3xx responses. DNS, TLS, timeout,
HTTP 4xx/5xx, and latency failures produce a non-zero exit status.

This is an unauthenticated infrastructure reachability check. It does not log in,
inspect a Foundry world, or prove that authenticated Foundry workflows succeed.

## 🔐 Security Best Practices

Protect state, saved plans, metadata, logs, and local secrets as well as cloud secret stores. Low-cost bootstrap stores credentials in state and instance user data; its host configuration directory is restricted to root. Do not print container environments or tunnel tokens while troubleshooting.

Review ingress per profile: low-cost AWS has no inbound rules and low-cost GCP permits IAP SSH only; their Foundry port is internal to Docker. Standard profiles include public load balancers and different administration rules. Configure Cloudflare Access separately when required.

Choose encryption and backup controls for each provider. Do not assume a managed database, scale group, or provider snapshot protects Foundry world files. Monitor disk usage, bootstrap failures, patch status, and restore success. The low-cost roots deliberately omit managed log ingestion and scheduled snapshots.

## 📊 Terraform Best Practices

This repository follows Terraform best practices:

- ✅ **Modular design**: Reusable modules for each cloud platform
- ✅ **Provider pinning**: Specific provider versions to avoid surprises
- ✅ **Naming conventions**: Consistent resource naming across platforms
- ✅ **Tagging**: Resources tagged with project, environment, and managed-by metadata
- ✅ **Outputs**: Meaningful outputs for integration with other tools
- ✅ **Documentation**: Clear operator guidance for multi-system deployments
- ✅ **Local values**: Repeated strings stored in locals for DRY principles
- ✅ **Variable validation**: Input validation with actionable error messages
- ✅ **Sensitive values**: Secrets marked sensitive to prevent logging

## 🐛 Troubleshooting

Run validation from the selected Terraform root and use [the validation matrix](docs/TERRAFORM_VALIDATION.md) to separate provider/schema failures from credentials, quotas, and runtime failures. Verify identity using `aws sts get-caller-identity`, `az account show`, or your GCP application-default credential setup. Hetzner uses the Terraform input `hcloud_token` (for example, `TF_VAR_hcloud_token` supplied by your secret manager).

On a low-cost host, inspect `sudo cloud-init status --long`, `sudo systemctl status legendforge`, `findmnt /srv/foundry-data`, and `sudo docker compose -f /opt/legendforge/compose.json logs --tail=100`. Treat logs as private. For standard profiles use their provider guide and actual container names. Check DNS, the configured Cloudflare route, and tunnel connector health in the Cloudflare dashboard without exposing tokens.

## 📈 Monitoring & Maintenance

AWS RDS, Azure managed databases, and GCP Cloud SQL have database backup controls. AWS/GCP storage buckets have their own policies. None proves that the active Foundry data disk has been backed up; the active Azure root does not attach VM backup protection through a Recovery Services Vault. Hetzner and both low-cost roots require operator-managed application backups.

Measure disk and memory use during sessions. Disk variable names and filesystem expansion steps differ by profile. Cloud-init is initial bootstrap: changing an image or credential variable does not guarantee an in-place application update and may propose replacement. Follow the [low-cost upgrade and restore procedure](docs/LOW_COST_OPERATIONS.md) or the selected provider guide.

### Multi-System Change Management

When switching or adding systems in Foundry:

1. Back up your world data first.
2. Verify the target system version is compatible with your Foundry release.
3. Introduce modules gradually and validate each world independently.
4. Document system-specific dependencies outside the infrastructure layer.

## 📚 Additional Resources

### Core Documentation

- [SUPPORTED_SYSTEMS.md](SUPPORTED_SYSTEMS.md) - System compatibility overview
- [PROJECT_PHILOSOPHY.md](PROJECT_PHILOSOPHY.md) - Universal tabletop infrastructure vision
- [ATTRIBUTION.md](ATTRIBUTION.md) - Technical attribution and license references
- [CREDITS.md](CREDITS.md) - Community recognition and acknowledgments
- [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md) - Documentation map
- [Published GitHub Wiki](https://github.com/sodejm/LegendForge-CloudCampaigns/wiki) - Rendered operator guides
- [Wiki synchronization](docs/WIKI_SYNC.md) - Canonical source, page map, and publication rules

### Official Documentation

- [Foundry VTT Docs](https://foundryvtt.com/article/installation/)
- [felddy/foundryvtt Docker Image](https://github.com/felddy/foundryvtt-docker) - ⭐ Thanks Felix!
- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)

### Cloud Provider Documentation

- [AWS Terraform Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [Azure Terraform Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
- [GCP Terraform Provider](https://registry.terraform.io/providers/hashicorp/google/latest)
- [Hetzner Cloud Terraform Provider](https://registry.terraform.io/providers/hetznercloud/hcloud/latest)

### Terraform Best Practices

- [Terraform AWS Best Practices](https://learn.hashicorp.com/terraform)
- [Terraform Module Best Practices](https://developer.hashicorp.com/terraform/language/modules/develop)

## 🙏 Attribution & Credits

LegendForge stands on the shoulders of giants. We gratefully use and credit:

- **[Foundry Virtual Tabletop](https://github.com/foundryvtt)** - The platform enabling many tabletop systems
- **[felddy/foundryvtt-docker](https://github.com/felddy/foundryvtt-docker)** - Essential Docker image maintained by @felddy
- **[Cloudflare Tunnel](https://www.cloudflare.com/products/tunnel/)** - Secure tunneling solution
- **[HashiCorp Terraform](https://www.terraform.io/)** - Infrastructure as Code platform
- **Cloud providers including AWS, Azure, GCP, and Hetzner** - Deployment flexibility across environments
- **[Docker](https://www.docker.com/)** - Container platform
- **[Ubuntu/Canonical](https://ubuntu.com/)** - Operating system and cloud-init ecosystem

📚 **Full Attribution:** See [ATTRIBUTION.md](ATTRIBUTION.md) for complete technical details.

👥 **Community Credits:** See [CREDITS.md](CREDITS.md) for recognition of contributors and maintainers.

## 📄 License

This Terraform configuration is provided as-is. See [LICENSE](LICENSE) for details.

## 🛡️ Code Quality and Security Gates

This repository uses **local git hooks** and **GitHub Actions** to enforce quality and security checks.

### Local Hooks (pre-commit + pre-push)

Install required tools:

```bash
# macOS
brew install terraform tflint trufflehog
python3 -m pip install --user pre-commit semgrep
```

Install hooks:

```bash
# Enforce repository-managed git hooks (blocks push on Semgrep/TruffleHog findings)
git config core.hooksPath .githooks

# Optional: pre-commit framework hooks
pre-commit install --hook-type pre-commit --hook-type pre-push
```

Run checks manually:

```bash
pre-commit run --all-files --hook-stage pre-commit
pre-commit run --all-files --hook-stage pre-push
```

What is enforced:

- `terraform fmt -check -recursive`
- `terraform validate` for each deployment directory
- `tflint` for each deployment directory
- `semgrep --config p/ci`
- `trufflehog` staged-file scan on commit and full repository scan on push

### CI Pipeline

After pushing to GitHub (`sodejm/LegendForge-CloudCampaigns`), the workflow at:

- `.github/workflows/quality-security.yml`

runs the same pre-commit and pre-push quality/security gates in CI.

## 🤝 Contributing

Contributions are welcome. Please:

1. Fork the repository
2. Create a feature branch
3. Add or update modules and documentation
4. Test on at least one platform
5. Preserve the LegendForge universal-tabletop positioning when editing docs
6. Submit a pull request

## ❓ FAQ

**Q: Is LegendForge only for D&D?**
A: No. LegendForge is intentionally system-agnostic infrastructure for Foundry deployments, including D&D 5e, Pathfinder, World of Darkness, Fate, PbtA, Forbidden Lands, GUMSHOE, and other compatible systems.

**Q: Can I migrate between platforms?**
A: Yes. Foundry data is stored on persistent volumes. Export data, back up the volume, and import to the new platform.

**Q: What's the expected monthly cost?**
A: Use the dated [deployment comparison](docs/DEPLOYMENT_MODEL_COMPARISON.md) and the selected profile's bill of materials. Region, operating hours, retained disks, traffic, backups, and managed services affect the total.

**Q: How do I update Foundry?**
A: Take and verify a restorable backup first, then follow the selected profile's maintenance procedure. The AWS/GCP low-cost profiles use the [shared update procedure](docs/LOW_COST_OPERATIONS.md); changing bootstrap variables alone does not update an existing server.

**Q: Can I use this for production?**
A: Yes, after reviewing the selected provider's availability and recovery model.
Standard AWS, Azure, and GCP profiles include more managed controls. The AWS/GCP
low-cost profiles and Hetzner use a single server whose backups, restore drills,
monitoring, and maintenance are operator responsibilities.

**Q: How do I access Foundry if Cloudflare is down?**
A: Profiles using Cloudflare Tunnel need a separate administrative access path. Follow the selected guide for SSM, IAP SSH, or provider-specific SSH/Bastion access; standard load-balancer profiles have a different ingress model.

---

**Last Updated:** September 5, 2026
**Project Identity:** LegendForge - universal tabletop infrastructure for Foundry VTT

## Milestone development workflow

Use the [reusable goal prompt](prompts/next-milestone.md) to run a bounded
milestone with an orchestrating agent. The [usage guide](prompts/README.md) covers
the shared skill, task-specific model routing, decision summaries, and safe storage.
