# How-To

This page collects common operator tasks using the existing repository guidance.

## How to Choose a Provider

- Choose **AWS** for broader enterprise patterns and scalability
- Choose **Azure** for Azure-native RBAC and portal-based operations
- Choose **GCP** for strong monitoring and managed service integrations
- Choose **Hetzner** for the lowest-cost, simplest production path

See [Provider Guide](Provider-Guide).

## How to Deploy a New Instance

1. Prepare `config/foundry.auto.tfvars`
2. Prepare `config/secrets.auto.tfvars`
3. Run `terraform init`
4. Run `terraform plan`
5. Run `terraform apply`
6. Validate outputs and access the Foundry URL

## How to Install a Game System

LegendForge does not install rulesets through Terraform.

After infrastructure is live:

1. Log in to Foundry
2. Install the system package that matches your Foundry version
3. Create or restore the world
4. Add modules gradually
5. Test the world before inviting players

## How to Operate Multiple Systems

- Keep Foundry core upgrades controlled
- Track which world uses which system and modules
- Validate heavy module stacks in a test world
- Consider separate worlds or separate deployments for very different communities
- Back up before system or module upgrades

## How to Access Running Infrastructure

### AWS

Use Systems Manager Session Manager.

### Azure

Use Bastion, SSH, or `az vm run-command invoke`.

### GCP

Use `gcloud compute ssh` with OS Login.

### Hetzner

Use SSH directly to the server IP when enabled.

## How to View Terraform State

From the provider deployment directory:

```bash
terraform state list
terraform output
```

Use provider-specific resource names when inspecting details with `terraform state show`.

## How to Spin Down and Bring Back Compute

LegendForge supports a cost-control pattern where compute can be disabled while persistent data remains.

Set:

```hcl
compute_enabled = false
```

Then re-apply Terraform. Re-enable later and apply again to bring the runtime back online.

## How to Prepare for Upgrades

Before major changes:

1. Back up world data
2. Snapshot persistent storage
3. Record the active Foundry version
4. Record system and module dependencies
5. Validate in a test world first

## How to Troubleshoot Safely

- Check Terraform outputs first
- Confirm DNS and Cloudflare Tunnel status
- Confirm the instance or scale set is healthy
- Check container logs
- Check database connectivity only after application health is known

## Related Pages

- [Quickstart](Quickstart)
- [Prompts](Prompts)
- [Use Cases](Use-Cases)
