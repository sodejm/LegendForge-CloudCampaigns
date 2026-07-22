# Hetzner Foundry VTT deployment

This is the low-cost, single-server LegendForge deployment. Terraform creates a Hetzner private network and firewall, one Ubuntu 22.04 server when compute is enabled, and one ext4 data volume attached to that server. Cloud-init installs Docker and starts `foundry` and `cloudflared` containers; Cloudflare Tunnel provides the intended public ingress.

It is a practical small-instance deployment, not a highly available or managed Foundry service. Read [Operational limits](#operational-limits-and-trade-offs) before using it for an active campaign.

## Topology and security posture

```text
Players -> Cloudflare DNS / Tunnel -> cloudflared container -> foundry container (port 30000)
                                              |
                         outbound tunnel from one Hetzner server
                                              |
                              attached ext4 volume at /opt/foundry/data
```

- **One failure domain:** the module has one `hcloud_server`, one data volume, and no load balancer, replica, managed database, or automatic failover.
- **Ingress:** the Terraform firewall adds no public Foundry rule. The Cloudflare Tunnel token must already be created and configured in Cloudflare so it routes the chosen hostname to the Foundry service. Terraform does not create the Cloudflare tunnel, DNS record, Access policy, or hostname route.
- **SSH:** `admin_ssh_cidr` is `null` by default, which leaves port 22 closed by this Terraform firewall. If break-glass SSH is required, set it to one trusted public address in CIDR notation (for example, `203.0.113.10/32`), keep the scope narrow, and remove it again when finished. This module does **not** install an SSH public key, so ensure access is provisioned by an approved Hetzner-console/manual process before relying on SSH.
- **Secrets:** keep the Cloudflare tunnel token, Foundry credentials, licence key, and admin key in an ignored secrets file or another approved secret store. Do not paste them in shell history, issue comments, Terraform output, or version control.

## Prerequisites

- Terraform 1.0 or later and a Hetzner Cloud account/API token.
- A Cloudflare-managed zone, plus a pre-created Cloudflare Tunnel and hostname route. Obtain its token from Cloudflare; this repository only passes it to `cloudflared`.
- Foundry image and licence configuration, along with an ignored secrets file.
- For backup or restore: an encrypted off-server storage location and a tested administrative access method. The Hetzner console is a manual prerequisite for provider snapshots/backups and recovery operations.

## Configure and deploy

Run these commands from this directory, `infrastructure/deployments/hetzner`. The repository `config/` directory is three levels above it.

```bash
# From repository root, create local configuration files once.
cp config/foundry.auto.tfvars.example config/foundry.auto.tfvars
# Create config/secrets.auto.tfvars through your approved secret-handling process.

cd infrastructure/deployments/hetzner
terraform init
terraform plan \
  -var-file="../../../config/foundry.auto.tfvars" \
  -var-file="../../../config/secrets.auto.tfvars"
terraform apply \
  -var-file="../../../config/foundry.auto.tfvars" \
  -var-file="../../../config/secrets.auto.tfvars"
```

Set `hcloud_token` in the secrets file (the provider is explicitly configured from that variable). Never commit the resulting `*.tfvars` files.

After apply, retrieve the public address and check bootstrap progress:

```bash
terraform output -raw server_public_ipv4
ssh root@"$(terraform output -raw server_public_ipv4)"

# On the server
cloud-init status --long
sudo tail -n 200 /var/log/cloud-init-output.log
cd /opt/foundry && sudo docker compose ps
sudo docker logs --tail=200 foundry
sudo docker logs --tail=200 cloudflared
```

SSH works only when a reachable SSH credential and a narrowly scoped `admin_ssh_cidr` have been deliberately provisioned. If SSH is closed, use the Hetzner console's approved recovery/access path instead.

## Sizing and cost

The Terraform defaults are `cx21`, `fsn1-dc14`, and a 20 GB volume. Treat them as a starting point for a small group, not a capacity commitment: monitor memory, CPU, and `/opt/foundry/data` during sessions, then choose a supported Hetzner server type and increase `data_volume_size_gb` when measured demand requires it.

As of 2026-07-20, repository planning material budgets this deployment at roughly **€6–8/month** for a small server and 20 GB volume, before optional services, taxes, backups, or transfer-related charges. This is an estimate, not a guarantee; confirm the current region, server type, volume, traffic, and backup pricing in the [Hetzner Cloud pricing page](https://www.hetzner.com/cloud/) before applying.

To request a larger data volume, change `data_volume_size_gb` and inspect the plan before applying. Volume growth and server-type changes are provider operations with possible restart or maintenance impact; take and verify an off-server backup first. The module does not expose an in-place server power-state control, so do not assume a Terraform apply will "pause" a server without replacement effects.

## Backup and recovery

Terraform state is not a backup. The Foundry data volume contains the state that matters, and the module has no scheduled backup resource.

### Off-server backup procedure

1. **Manual prerequisite:** ensure a tested SSH/console route to the server and an encrypted off-server destination owned by the operator (for example, an approved backup host or object storage workflow). Do not put destination credentials in Terraform variables.
2. Schedule a maintenance window, stop Foundry for a consistent application-level archive, and archive the mounted data directory. The volume is mounted at the configured `data_mount_path` (default `/opt/foundry/data`).

   ```bash
   # Run on the server after verifying the mount with: findmnt /opt/foundry/data
   cd /opt/foundry
   sudo docker compose stop foundry
   sudo tar --numeric-owner -C /opt/foundry/data -czf /tmp/foundry-data-$(date +%F).tgz .
   sudo docker compose start foundry
   ```

3. Transfer the archive to the approved off-server destination, verify its checksum there, and record the restore instructions and retention date. Remove the temporary local archive only after verification.
4. Optionally create a Hetzner volume snapshot/backup through the **Hetzner console or an approved operator workflow**. That provider-side copy is useful for rapid recovery but is not an off-provider backup and does not replace step 3.
5. Periodically test a restore in a non-production environment. A backup is only trustworthy after a successful restore test.

### Restore procedure

1. **Manual prerequisite:** use the Hetzner console/operator workflow to recover or replace infrastructure as needed, and keep the server isolated from player traffic until validation completes.
2. Apply this deployment to create the server and data volume, then wait for cloud-init and Docker to finish. Confirm the volume mount path with `findmnt`.
3. Stop Foundry, copy the verified off-server archive to the server, extract it into the mounted data directory with ownership preserved, then start Foundry:

   ```bash
   cd /opt/foundry
   sudo docker compose stop foundry
   sudo tar --numeric-owner -C /opt/foundry/data -xzf /path/to/verified/foundry-data.tgz
   sudo docker compose start foundry
   sudo docker logs --tail=200 foundry
   ```

4. Verify worlds, assets, user access, Cloudflare Tunnel connectivity, and application logs before reopening access.

The Terraform module has no input for attaching an existing restored volume. If recovery requires a provider-restored volume rather than an application-level archive, the attach/import steps are a **manual operator procedure** outside this configuration; plan and test them before an incident.

## Lifecycle operations

Use the same two var files for every command below and inspect `terraform plan` before an apply or destroy.

### Routine monitoring

```bash
# From infrastructure/deployments/hetzner
terraform output

# On the server
df -h /opt/foundry/data
free -h
sudo docker compose -f /opt/foundry/docker-compose.yml ps
sudo docker logs --tail=200 foundry
sudo docker logs --tail=200 cloudflared
```

Also monitor Cloudflare Tunnel status and access logs in the Cloudflare dashboard. The Terraform configuration does not provision monitoring alerts, log retention, health-based recovery, or automatic backups.

### Pause and resume

There is no safe, data-preserving Terraform pause in the current Hetzner module. Setting `compute_enabled=false` removes the server **and** the Terraform-managed data volume because both resources use that setting as their `count`. It can therefore delete Foundry data.

Do not use `compute_enabled=false` as a cost-saving pause unless a tested backup exists and data loss is acceptable. For a short operational pause, use a manual Hetzner-console server power action only after checking its billing and volume consequences; that action is outside Terraform and must be reconciled with state before the next apply. To resume after a manual power action, use the console and then verify the volume mount, Docker containers, and tunnel status.

### Resize

1. Create and verify an off-server backup.
2. Change `server_type` or increase `data_volume_size_gb` in `config/foundry.auto.tfvars`.
3. From this directory, run the normal `terraform plan` command and review whether the provider will stop, replace, or otherwise disrupt the server.
4. Apply only during a maintenance window, then verify the application, mount, and tunnel.

Shrinking a volume is not represented by this module; do not attempt it through a smaller variable value without a separate migration and restore plan.

### Destroy

```bash
terraform destroy \
  -var-file="../../../config/foundry.auto.tfvars" \
  -var-file="../../../config/secrets.auto.tfvars"
```

Destroying this deployment deletes the server and the Terraform-managed data volume. Confirm that an off-server backup has been verified before running it. The network and firewall are also managed resources and are removed by destroy.

## Operational limits and trade-offs

- **Availability:** one server, one volume, one region, and no failover mean provider, host, network, Cloudflare, Docker, or volume failure can cause an outage.
- **Recovery:** no automated backup or restore orchestration is supplied. Recovery time and data-loss exposure depend on the operator's tested off-server backups and manual console access.
- **Security:** public Foundry access is designed to flow through Cloudflare Tunnel, and SSH is closed by default. Cloudflare routing/Access configuration and secure credential rotation remain operator responsibilities. A broad SSH CIDR weakens the intended posture.
- **Data lifecycle:** the current `compute_enabled` implementation does not retain its managed data volume. Treat all teardown-like operations as destructive unless a reviewed plan proves otherwise.
- **Operations:** there are no Terraform-managed alerts, managed patching, snapshot schedule, autoscaling, or multi-node capacity. Ubuntu package updates and cloud-init run at first boot; ongoing patching and monitoring are operator work.

## References

- [Hetzner Cloud documentation](https://docs.hetzner.cloud)
- [Hetzner Cloud Terraform provider](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs)
- [Cloudflare Tunnel documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
- [Foundry VTT Docker image](https://github.com/felddy/foundryvtt-docker)
