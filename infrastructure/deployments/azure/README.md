# LegendForge on Azure

This is the canonical guide for the Terraform configuration in this directory.
It describes what `main.tf` currently provisions, rather than the older
root-level Azure documents. Review the generated Terraform plan before using it
for any environment with real Foundry or database data.

## What this deployment creates

The root configuration composes these modules:

- A resource group, VNet, four subnets, network security groups, a Standard NAT
  gateway, and Azure DDoS Protection Standard.
- A public Standard Load Balancer in front of a Linux VM Scale Set. HTTP on
  port 80 maps to the application health endpoint on port 30000; HTTPS on 443
  maps to 30001. The scale set uses a user-assigned managed identity and a
  rolling upgrade policy.
- An Azure Database Flexible Server (MySQL by default; PostgreSQL is selectable),
  a database, private DNS, a delegated database subnet, and service backups.
- A private storage account with four private containers, a Blob private
  endpoint, a Key Vault with private endpoint and access policy, and optional
  Azure CDN.
- When `enable_monitoring` is true, Log Analytics, Application Insights,
  diagnostic settings, an email action group, alerts, and a dashboard.

The scale set has CPU autoscaling: it adds one instance above 75% average CPU
for five minutes and removes one below 25%, within the configured min/max
capacity. A second memory-based policy is also declared. Verify both policies
in the Terraform plan and Azure Monitor before relying on them operationally.

## Before you begin

You need an Azure subscription in which you can create the resources above,
Azure CLI (`az`), Terraform, and a Foundry VTT license key. Azure authentication
also supplies the tenant and principal IDs used by the Key Vault module.

From this directory, authenticate and select the intended subscription:

```sh
az login
az account show
az account set --subscription "<subscription-id-or-name>"
az account show
```

Create an SSH key if you do not already have an approved public key. Put only
the public-key contents in Terraform variables; keep the private key outside
this repository.

```sh
ssh-keygen -t rsa -b 4096 -f "$HOME/.ssh/legendforge_azure"
cat "$HOME/.ssh/legendforge_azure.pub"
```

`terraform.tfvars` and Terraform state can contain secrets, including the
Foundry license, database password, storage key, and Key Vault secrets. Do not
commit, paste into issue comments, or upload either without an approved secure
storage process.

## Configure an environment

```sh
cd infrastructure/deployments/azure
cp terraform.tfvars.example terraform.tfvars
chmod 600 terraform.tfvars
```

Edit `terraform.tfvars`. These are the root variables actually consumed by the
deployment:

| Area | Variables | Notes |
| --- | --- | --- |
| Naming and network | `environment`, `location`, `project_name`, `vnet_address_space`, `common_tags` | `environment` must be `dev`, `staging`, or `prod` in the networking module. The supplied subnet layout assumes `10.0.0.0/16`; change it only after checking every subnet and database firewall rule. |
| Foundry and access | `foundry_version`, `foundry_license_key`, `vm_admin_username`, `vm_ssh_public_key` | The license and public SSH key are required. The initialization template starts Foundry on port 30000. |
| Database | `database_engine`, `database_version`, `database_sku_name`, `database_storage_size`, `database_admin_username`, `database_password`, `backup_retention_days`, `geo_redundant_backup_enabled`, `high_availability_enabled` | The implementation selects MySQL only when the engine is exactly `mysql`; it otherwise selects PostgreSQL. Confirm the chosen engine/version/SKU is available in the selected region before applying. |
| Scale set | `vm_size`, `scale_set_capacity`, `scale_set_min_capacity`, `scale_set_max_capacity` | Keep all capacities internally consistent; the Terraform configuration itself does not add a root-level validation for this. |
| Optional services | `enable_monitoring`, `alert_email`, `enable_cdn` | `alert_email` is still required by the variable schema even when monitoring is disabled. |

Use unique values for `project_name` and a dedicated environment to avoid
colliding with existing Azure resource names. Do not use the example password
in `terraform.tfvars.example`.

### Standard profile

The example template is the standard profile: `Standard_D4s_v5`, two initial
instances, minimum two, maximum ten, `Standard_B2s` database, 100 GB database
storage, monitoring and CDN enabled, 35-day backup retention, geo-redundant
backups, and database high availability. This profile still requires a reviewed
plan; it is not a cost quote or a production approval.

### Low-cost profile

For a non-production, interruption-tolerant environment, change only existing
root variables to a profile such as:

```hcl
environment                  = "dev"
vm_size                      = "Standard_B2s"
scale_set_capacity           = 1
scale_set_min_capacity       = 1
scale_set_max_capacity       = 1
database_sku_name            = "Standard_B1ms"
database_storage_size        = 20
backup_retention_days        = 7
geo_redundant_backup_enabled = false
high_availability_enabled    = false
enable_monitoring            = false
enable_cdn                   = false
```

These values are not a provider price estimate. Verify SKU and minimum-storage
availability in your selected region during `terraform plan`. This profile
still creates networking, NAT, DDoS Protection, a public load balancer, private
endpoints, storage, Key Vault, and a database; those are not exposed as root
cost switches. It has no application redundancy, no database HA, no geo backup,
and no monitoring resources from this configuration. It is unsuitable for
production workloads or data without a separate, tested backup plan.

## Plan and deploy

Run commands from `infrastructure/deployments/azure`.

```sh
terraform init
terraform fmt -check
terraform validate
terraform plan -out=tfplan
terraform show tfplan
terraform apply tfplan
terraform output
```

The repository also provides `./deploy.sh`, which checks for `az` and
Terraform, creates `terraform.tfvars` from the example if missing, runs init,
validate, a recursive format command, creates `tfplan`, prompts, applies it,
and writes `deployment_outputs.json`. It is interactive and its recursive
format step can modify Terraform files outside this deployment directory. Use
the explicit commands above when you need a reviewable plan or a clean working
tree; use the script only after reviewing those effects.

After apply, obtain the endpoint from the state rather than constructing a
resource name:

```sh
terraform output -raw foundry_url
terraform output -raw load_balancer_public_ip
terraform output -raw resource_group_name
terraform output -raw scale_set_name
```

The load balancer exposes a plain `http://` URL in the current output. The
configuration creates a TCP listener on 443 but does not configure a TLS
certificate or hostname. Do not describe the deployment as HTTPS-ready until a
separate, reviewed TLS termination configuration exists.

## Validate and operate

Use outputs to avoid the stale hard-coded names in `maintenance.sh` and the
informational commands printed by `deploy.sh`:

```sh
RESOURCE_GROUP="$(terraform output -raw resource_group_name)"
SCALE_SET="$(terraform output -raw scale_set_name)"
PUBLIC_IP="$(terraform output -raw load_balancer_public_ip)"

az vmss show --resource-group "$RESOURCE_GROUP" --name "$SCALE_SET"
az vmss list-instances --resource-group "$RESOURCE_GROUP" --vmss-name "$SCALE_SET"
curl --fail "http://${PUBLIC_IP}/api/health"
```

Use Azure Portal or Azure Monitor to review metric alerts and diagnostic data
when monitoring is enabled. `maintenance.sh` is a menu of useful diagnostics,
but it hard-codes `rg-dnd-foundry-prod` and `vmss-dnd-foundry-prod`; do not run
it unchanged for a differently named deployment. Its backup menu item is not a
validated restore workflow for this Terraform configuration.

To make an intentional capacity change, update all three scale-set values in
`terraform.tfvars`, then review and apply the plan:

```sh
terraform plan -out=tfplan
terraform show tfplan
terraform apply tfplan
```

Avoid direct manual scaling unless it is an emergency. The autoscale settings
and the next Terraform apply can overwrite out-of-band changes.

## Backup, restore, pause, and destroy

The database resources configure Azure Flexible Server backup retention and
optionally geo-redundant backups. This repository does **not** configure a
backup of Foundry's `/opt/foundry/data` directory: the current cloud-init
template uses that local path and does not upload it to the provisioned storage
containers. Treat database backups and application-data backups as separate
requirements.

Before a disruptive operation, save the Terraform state only to approved,
encrypted storage; it contains sensitive values. This is an infrastructure
recovery input, not a Foundry data backup:

```sh
terraform state pull > "legendforge-azure-$(date -u +%Y%m%dT%H%M%SZ).tfstate"
```

To pause the application tier without deleting resources, set the three
scale-set capacity variables to `0` and apply the reviewed plan. The module
does not prohibit zero capacity, but test this in a non-production environment
first: the public load balancer and database remain billed and the service is
unavailable. Resume by restoring the intended capacity values and applying a
new plan.

```sh
terraform plan -out=tfplan
terraform show tfplan
terraform apply tfplan
```

To rebuild infrastructure from an approved state and configuration, run init,
review the plan, and apply. A rebuild does not restore Foundry data unless you
have independently backed it up and tested the application-level restore.

```sh
terraform init
terraform plan -out=tfplan
terraform show tfplan
terraform apply tfplan
```

Destroy is irreversible for resources and may leave protected Key Vault data
according to Azure retention/protection behavior. Back up data first, obtain
the required approval, then use a destroy plan rather than a blind command:

```sh
terraform plan -destroy -out=destroy.tfplan
terraform show destroy.tfplan
terraform apply destroy.tfplan
```

## Security, availability, and cost trade-offs

- The deployment uses private endpoints for Blob Storage and Key Vault, private
  DNS zones, private storage containers, Key Vault network ACLs, a managed
  identity, and an SSH public key. The application endpoint is nonetheless
  public through the load balancer, and the current Key Vault allows public
  network access while denying by default; review these settings against your
  organization’s policy.
- Scale-set instances are distributed across zones and the database supports
  ZoneRedundant HA when enabled. Two or more instances and database HA improve
  resilience but do not by themselves provide a complete disaster-recovery or
  application-data-backup design.
- Primary cost drivers are VM size/count, Flexible Server SKU/storage/backup
  options, NAT gateway, DDoS Protection Standard, public load balancer, private
  endpoints, storage/CDN traffic, and optional monitoring ingestion/retention.
  Obtain current regional prices from Azure before approving a plan.
- The values passed to the compute module include database and storage
  credentials in cloud-init. Terraform state and deployment logs must therefore
  be handled as sensitive operational material.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| `terraform init` or plan cannot authenticate | Run `az account show`, select the intended subscription, then retry. Confirm the identity can create resources and access the tenant used by Key Vault. |
| A database SKU/version fails in the plan or apply | Confirm the selected `database_engine`, `database_version`, `database_sku_name`, storage size, HA, and geo-backup combination is supported in the chosen region. |
| Scale set has no healthy instances | Check the scale-set instance state, then the `/api/health` endpoint through the output public IP. The health probe requires the application to respond on port 30000. |
| Foundry is unreachable on HTTPS | The Terraform configuration does not provision a certificate or TLS termination. Validate HTTP health first and design TLS separately. |
| `maintenance.sh` targets nonexistent resources | The script contains fixed D&D Foundry resource names. Use Terraform outputs and the commands in this guide instead. |
| A change seems to be reversed | Compare the Azure resource with `terraform plan`; direct Azure changes are outside Terraform’s desired state and may be reconciled on apply. |

For every production change, preserve the reviewed plan, record the subscription
and region, and verify both the application health endpoint and the required
data-recovery procedure.
